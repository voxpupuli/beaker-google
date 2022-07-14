# frozen_string_literal: true

require 'google/apis/compute_v1'
require 'google/apis/oslogin_v1'
require 'googleauth'
require 'json'
require 'time'
require 'ostruct'

# TODO: Figure out what to do about the timeout thing
# TODO: Allow setting the size of the instance
# TODO: Documentation pass on all parameters
# TODO: Implement Google::Apis::RequestOptions on all calls (In lib/google/apis/options.rb)

# Beaker helper module for doing API level Google Compute Engine interaction.
class Beaker::GoogleComputeHelper
  class GoogleComputeError < StandardError
  end

  SLEEPWAIT = 5

  AUTH_URL = 'https://www.googleapis.com/auth/compute'
  API_VERSION = 'v1'
  BASE_URL = "https://www.googleapis.com/compute/#{API_VERSION}/projects/"
  CENTOS_PROJECT = 'centos-cloud'
  DEBIAN_PROJECT = 'debian-cloud'
  RHEL_PROJECT = 'rhel-cloud'
  SLES_PROJECT = 'sles-cloud'
  DEFAULT_ZONE_NAME = 'us-central1-a'
  DEFAULT_MACHINE_TYPE = 'e2-standard-4'
  DEFAULT_NETWORK_NAME = 'default'

  GCP_AUTH_SCOPE = [
    Google::Apis::ComputeV1::AUTH_COMPUTE,
    Google::Apis::OsloginV1::AUTH_CLOUD_PLATFORM_READ_ONLY,
  ].freeze

  # Create a new instance of the Google Compute Engine helper object
  #
  # @param [Hash{Symbol=>String}] options The options hash containing
  # configuration values
  #
  # @option options [String] :gce_project The Google Compute Project name to
  # connect to
  #
  # @option options [String] :gce_keyfile The location of the Google Compute
  # service account keyfile
  #
  # @option options [String] :gce_password The password for the Google Compute
  # service account key
  #
  # @option options [String] :gce_email The email address for the Google
  # Compute service account
  #
  # @option options [String] :gce_machine_type A Google Compute machine type
  # used to create instances, defaults to n1-highmem-2
  #
  # @option options [Integer] :timeout The amount of time to attempt execution
  # before quiting and exiting with failure
  def initialize(options)
    @options = options
    @logger = options[:logger]
    # try = 1
    # attempts = @options[:timeout].to_i / SLEEPWAIT
    # start = Time.now

    set_client(Beaker::Version::STRING)
    ::Google::Apis.logger = ::Logger.new(::STDERR)
    # ::Google::Apis.logger.level = ::Logger::DEBUG
    ::Google::Apis.logger.level = ::Logger::WARN

    # set_compute_api(API_VERSION, start, attempts)

    @options[:gce_project] = ENV['BEAKER_gce_project'] if ENV['BEAKER_gce_project']

    @options[:gce_zone] = ENV.fetch('BEAKER_gce_zone', DEFAULT_ZONE_NAME)
    @options[:gce_network] = ENV.fetch('BEAKER_gce_network', DEFAULT_NETWORK_NAME)
    @options[:gce_subnet] = ENV.fetch('BEAKER_gce_subnet', nil)

    # @options[:gce_keyfile] = ENV["BEAKER_gce_keyfile"] if ENV["BEAKER_gce_keyfile"]

    # unless (@options[:gce_keyfile] && File.exist?(@options[:gce_keyfile]))
    #   @options[:gce_keyfile] = File.join(ENV["HOME"], ".beaker", "gce", %(#{@options[:gce_project]}.p12))
    # end

    raise 'You must specify a gce_project for Google Compute Engine instances!' unless @options[:gce_project]

    authorizer = authenticate
    @compute = ::Google::Apis::ComputeV1::ComputeService.new
    @compute.authorization = authorizer

    # Find the appropriate username to log into created instances
    @cloudoslogin = Google::Apis::OsloginV1::CloudOSLoginService.new
    @cloudoslogin.authorization = authorizer
  end

  ##
  # Determines the default Google Compute zone based upon options and
  # defaults
  #
  # @return [String] The name of the zone
  def default_zone
    @options[:gce_zone]
  end

  ##
  # Get the region name from the provided zone.
  #
  # Assume that the region is the name of the zone without
  # the final - and zone letter
  #
  # @return [String] The name of the region
  def default_region
    @options[:gce_zone].split('-')[0..1].join('-')
  end

  ##
  # Determines the default Google Compute network based upon defaults and
  # options
  #
  # @return [String] The short name of the VPC network
  def default_network
    @options[:gce_network]
  end

  ##
  # Find the username for ssh to use with this connection
  #
  # @return [String] The username for ssh
  #
  # @raise [Google::Auth::IDTokens::KeySourceError] if the key source failed to obtain public keys
  # @raise [Google::Auth::IDTokens::VerificationError] if the token verification failed.
  #     Additional data may be available in the error subclass and message.
  def ssh_username
    authorizer = @compute.authorization
    # This is a bit of a hack based on what I found in a user (default application credentials)
    # and a service account. There might be a better way of doing this.
    case authorizer.class.to_s
    when 'Google::Auth::UserRefreshCredentials'
      authorizer.refresh!
      userid = ::Google::Auth::IDTokens.verify_oidc(authorizer.id_token)['email']
    when 'Google::Auth::ServiceAccountCredentials'
      userid = authorizer.issuer
    else
      raise 'Unknown type of credential'
    end
    userid = "users/#{userid}" unless userid.start_with? 'users/'
    @cloudoslogin.get_user_login_profile(userid).posix_accounts[0].username
  end

  ##
  # Infer the network that a given subnetwork is attached to
  #
  # @param [String] subnetwork_name The name of the subnetwork
  #
  # @return [String] The short name of the network
  #
  # @raise [Google::Apis::ServerError] An error occurred on the server and the request can be retried
  # @raise [Google::Apis::ClientError] The request is invalid and should not be retried without modification
  # @raise [Google::Apis::AuthorizationError] Authorization is required
  def default_network_from_subnet(subnetwork_name)
    subnetwork = @compute.get_subnetwork(@options[:gce_project], default_region, subnetwork_name)
    m = %r{.*/networks/(?<network_name>.*)\Z}.match subnetwork.network
    nil if m.nil?
    m['network_name']
  end

  ##
  # Determine the subnetwork to use for instances
  #
  # If the network is the 'default' network, get the 'default' subnetwork for the region.
  # If no subnet is provided by the user, pick the first one out of the user-provided network
  #
  # @return [String] The name of the subnetwork that should be attached to the instances
  def default_subnetwork
    network_name = @options[:gce_network]
    if network_name == 'default'
      @options[:gce_subnet] ||= @compute.get_subnetwork(@options[:gce_project], default_region, 'default')
    elsif @options[:gce_subnet].nil?
      # No subnet set, get the first subnet in our current region for the network
      # network = @compute.get_network(@options[:gce_project], @options[:gce_network])
      subnetwork = @compute.get_network(@options[:gce_project], network_name).subnetworks[0]
      m = %r{.*/subnetworks/(?<subnetwork_name>.*)\Z}.match subnetwork
      raise "Unable to find a subnetwork in provided network #{network_name}" if m.nil?

      @options[:gce_subnet] = m['subnetwork_name']
    end
    @options[:gce_subnet]
  end

  ##
  # Set the user-agent information for the application.
  #
  # @param version The version number of Beaker currently running
  def set_client(version)
    ::Google::Apis::ClientOptions.default.application_name = 'beaker-google'
    ::Google::Apis::ClientOptions.default.application_version = version
  end

  # Creates an authenticated connection to the Google Compute Engine API
  #
  # This method currently supports using application credentials via the
  # GOOGLE_APPLICATION_CREDENTIALS environment variable, and application default
  # credentials.
  #
  # @raise [Exception] Raised if we fail to create an authenticated
  # connection to the Google Compute API, either through errors or running
  # out of attempts
  def authenticate
    if ENV['GOOGLE_APPLICATION_CREDENTIALS']
      ::Google::Auth::ServiceAccountCredentials.from_env(scope: GCP_AUTH_SCOPE)
    else
      # Fall back to default application auth
      ::Google::Auth.get_application_default(GCP_AUTH_SCOPE)
    end
  end

  # Determines the latest image available for the provided platform name.
  #
  # Only images of the form (platform)-(version)-(version) are currently supported
  #
  # @param [String] platform The platform type to search for an instance of.
  #
  # @param [Integer] start The time when we started code execution, it is
  # compared to Time.now to determine how many further code execution
  # attempts remain
  #
  # @param [Integer] attempts The total amount of attempts to execute that we
  # are willing to allow
  #
  # @return [Hash] The image hash of the latest, non-deprecated image for the
  # provided platform
  #
  # @raise [Exception] Raised if we fail to execute the request, either
  # through errors or running out of attempts
  def get_latest_image(image_project, image_name)
    images = @compute.list_images(image_project, filter: "name=#{image_name}")
    raise "No image named #{image_name} found in project #{image_project}" if images.nil?
    raise "Unable to find a single image matching #{image_name}, found #{images.items.length} results" if images.items.length > 1

    images.items[0]
  end

  def get_latest_image_from_family(image_project, family_name)
    imagefamilyview = @compute.get_image_family_view(image_project, @options[:gce_zone], family_name)
    imagefamilyview.image
  rescue ::Google::Apis::ClientError => e
    raise e if e.status_code != 404
    nil
  end

  # Determines the Google Compute machineType object based upon the selected
  # gce_machine_type option
  #
  # @param [Integer] start The time when we started code execution, it is
  # compared to Time.now to determine how many further code execution
  # attempts remain
  #
  # @param [Integer] attempts The total amount of attempts to execute that we
  # are willing to allow
  #
  # @return [Hash] The machineType hash
  #
  # @raise [Exception] Raised if we fail get the machineType, either through
  # errors or running out of attempts
  def get_machine_type(_start, _attempts)
    @compute.list_machine_types(@options[:gce_project], default_zone,
                                filter: "name=#{@options[:gce_machine_type] || DEFAULT_MACHINE_TYPE} AND zone=#{default_zone}").items[0]
  end

  # Determines the Google Compute network object in use for the current connection
  # @param [Integer] start The time when we started code execution, it is
  # compared to Time.now to determine how many further code execution
  # attempts remain
  #
  # @param [Integer] attempts The total amount of attempts to execute that we
  # are willing to allow
  #
  # @return [Hash] The network hash
  #
  # @raise [Exception] Raised if we fail get the network, either through
  # errors or running out of attempts
  def get_network(network_name = default_network)
    @compute.get_network(@options[:gce_project], network_name)
  end

  # Determines a list of existing Google Compute instances
  #
  # @param [Integer] start The time when we started code execution, it is
  # compared to Time.now to determine how many further code execution
  # attempts remain
  #
  # @param [Integer] attempts The total amount of attempts to execute that we
  # are willing to allow
  #
  # @return [Array[Hash]] The instances array of hashes
  #
  # @raise [Exception] Raised if we fail determine the list of existing
  # instances, either through errors or running out of attempts
  def list_instances(_start, _attempts)
    @compute.list_instances(@options[:gce_project], default_zone).items
  end

  # Determines a list of existing Google Compute disks
  #
  # @param [Integer] start The time when we started code execution, it is
  # compared to Time.now to determine how many further code execution
  # attempts remain
  #
  # @param [Integer] attempts The total amount of attempts to execute that we
  # are willing to allow
  #
  # @return [Array[Hash]] The disks array of hashes
  #
  # @raise [Exception] Raised if we fail determine the list of existing
  # disks, either through errors or running out of attempts
  def list_disks(_start, _attempts)
    @compute.list_disks(@options[:gce_project], default_zone).items
  end

  # Determines a list of existing Google Compute firewalls
  #
  # @param [Integer] start The time when we started code execution, it is
  # compared to Time.now to determine how many further code execution
  # attempts remain
  #
  # @param [Integer] attempts The total amount of attempts to execute that we
  # are willing to allow
  #
  # @return [Array[Hash]] The firewalls array of hashes
  #
  # @raise [Exception] Raised if we fail determine the list of existing
  # firewalls, either through errors or running out of attempts
  def list_firewalls(_start, _attempts)
    @compute.list_firewalls(@options[:gce_project],
                            filter: 'name != default-allow-internal AND name != default-ssh').items
  end

  # Create a Google Compute firewall on the current connection
  #
  # @param [String] name The name of the firewall to create
  #
  # @param [Hash] network The Google Compute network hash in which to create
  # the firewall
  #
  # @param [Integer] start The time when we started code execution, it is
  # compared to Time.now to determine how many further code execution
  # attempts remain
  #
  # @param [Integer] attempts The total amount of attempts to execute that we
  # are willing to allow
  #
  # @raise [Exception] Raised if we fail create the firewall, either through
  # errors or running out of attempts
  def create_firewall(name, network)
    # execute(firewall_insert_req(name, network["selfLink"]), start, attempts)
    firewall_object = ::Google::Apis::ComputeV1::Firewall.new(
      name: name,
      allowed: [
        ::Google::Apis::ComputeV1::Firewall::Allowed.new(ip_protocol: 'tcp',
                                                         ports: ['443', '8140', '61613', '8080', '8081', '22']),
      ],
      network: network.self_link,
      # TODO: Is there a better way to do this?
      sourceRanges: ['0.0.0.0/0'], # Allow from anywhere
    )
    operation = @compute.insert_firewall(@options[:gce_project], firewall_object)
    @compute.wait_global_operation(@options[:gce_project], operation.name)
  end

  # Add a taget_tag to an existing firewall
  #
  # @param [String] the name of the firewall to update
  #
  # @ param [String] tag The tag to add to the firewall
  #
  # @raise [Google::Apis::ServerError] An error occurred on the server and the request can be retried
  # @raise [Google::Apis::ClientError] The request is invalid and should not be retried without modification
  # @raise [Google::Apis::AuthorizationError] Authorization is required
  def add_firewall_tag(name, tag)
    firewall = @compute.get_firewall(@options[:gce_project], name)
    firewall.target_tags = [] if firewall.target_tags.nil?
    firewall.target_tags << tag
    operation = @compute.patch_firewall(@options[:gce_project], name, firewall)
    @compute.wait_global_operation(@options[:gce_project], operation.name)
  end

  # Create a Google Compute disk on the current connection
  #
  # @param [String] name The name of the disk to create
  #
  # @param [Hash] img The Google Compute image to use for instance creation
  #
  # @param [Integer] start The time when we started code execution, it is
  # compared to Time.now to determine how many further code execution
  # attempts remain
  #
  # @param [Integer] attempts The total amount of attempts to execute that we
  # are willing to allow
  #
  # @raise [Exception] Raised if we fail create the disk, either through
  # errors or running out of attempts
  def create_disk(name, size, img = nil)
    # create a new disk for this instance
    new_disk = ::Google::Apis::ComputeV1::Disk.new(
      name: name,
      size_gb: size,
      source_image: img,
    )
    operation = @compute.insert_disk(@options[:gce_project], @options[:gce_zone], new_disk)
    @compute.wait_zone_operation(@options[:gce_project], @options[:gce_zone], operation.name)
  end

  # Create a Google Compute instance on the current connection
  #
  # @param [String] name The name of the instance to create
  #
  # @param [Hash] img The Google Compute image to use for instance creation
  #
  # @param [Hash] machine_type The Google Compute machineType
  #
  # @param [Hash] disk The Google Compute disk to attach to the newly created
  # instance
  #
  # @param [Integer] start The time when we started code execution, it is
  # compared to Time.now to determine how many further code execution
  # attempts remain
  #
  # @param [Integer] attempts The total amount of attempts to execute that we
  # are willing to allow
  #
  # @raise [Exception] Raised if we fail create the instance, either through
  # errors or running out of attempts
  def create_instance(name, img, machine_type, disk_size)
    initialize_params = ::Google::Apis::ComputeV1::AttachedDiskInitializeParams.new(
      disk_size_gb: disk_size,
      source_image: img.self_link,
    )
    disk_params = ::Google::Apis::ComputeV1::AttachedDisk.new(
      boot: true,
      auto_delete: true,
      initialize_params: initialize_params,
    )
    # attached_network = ::Google::Apis::ComputeV1::networkInterfaces.new()
    tags = ::Google::Apis::ComputeV1::Tags.new(
      items: [name],
    )
    network_interface = ::Google::Apis::ComputeV1::NetworkInterface.new(
      network: get_network(default_network).self_link,
      subnetwork: @compute.get_subnetwork(@options[:gce_project], default_region, default_subnetwork).self_link,
      # Create an AccessConfig to add a NAT IP to the host.
      # TODO: Make this configurable
      access_configs: [
        ::Google::Apis::ComputeV1::AccessConfig.new(
          network_tier: 'STANDARD',
        ),
      ],
    )
    new_instance = ::Google::Apis::ComputeV1::Instance.new(
      machine_type: machine_type.self_link,
      name: name,
      disks: [disk_params],
      network_interfaces: [network_interface],
      tags: tags,
    )
    operation = @compute.insert_instance(@options[:gce_project], @options[:gce_zone], new_instance)
    @compute.wait_zone_operation(@options[:gce_project], @options[:gce_zone], operation.name)
  end

  def get_instance(name)
    @compute.get_instance(@options[:gce_project], @options[:gce_zone], name)
  end

  # Set key/value metadata pairs to a Google Compute instance
  #
  # @param [String] name The name of the instance to set metadata
  #
  # @param [String] data An array of hashes to set ass metadata. Each array
  # item should have a 'key' and 'value' key.
  #
  # @return [Google::Apis::ComputeV1::Operation]
  #
  # @raise [Google::Apis::ServerError] An error occurred on the server and the request can be retried
  # @raise [Google::Apis::ClientError] The request is invalid and should not be retried without modification
  # @raise [Google::Apis::AuthorizationError] Authorization is required
  def set_metadata_on_instance(name, data)
    instance = @compute.get_instance(@options[:gce_project], @options[:gce_zone], name)
    mdata = instance.metadata.dup
    mdata.items = data
    operation = @compute.set_instance_metadata(@options[:gce_project], @options[:gce_zone], name, mdata)
    @compute.wait_zone_operation(@options[:gce_project], @options[:gce_zone], operation.name)
  end

  # Delete a Google Compute instance on the current connection
  #
  # @param [String] name The name of the instance to delete
  #
  # @param [Integer] start The time when we started code execution, it is
  # compared to Time.now to determine how many further code execution
  # attempts remain
  #
  # @param [Integer] attempts The total amount of attempts to execute that we
  # are willing to allow
  #
  # @raise [Exception] Raised if we fail delete the instance, either through
  # errors or running out of attempts
  def delete_instance(name)
    operation = @compute.delete_instance(@options[:gce_project], default_zone, name)
    @compute.wait_zone_operation(@options[:gce_project], @options[:gce_zone], operation.name)
  end

  # Delete a Google Compute disk on the current connection
  #
  # @param [String] name The name of the disk to delete
  #
  # @param [Integer] start The time when we started code execution, it is
  # compared to Time.now to determine how many further code execution
  # attempts remain
  #
  # @param [Integer] attempts The total amount of attempts to execute that we
  # are willing to allow
  #
  # @raise [Exception] Raised if we fail delete the disk, either through
  # errors or running out of attempts
  def delete_disk(name)
    operation = @compute.delete_disk(@options[:gce_project], default_zone, name)
    @compute.wait_zone_operation(@options[:gce_project], @options[:gce_zone], operation.name)
  end

  # Delete a Google Compute firewall on the current connection
  #
  # @param [String] name The name of the firewall to delete
  #
  # @param [Integer] start The time when we started code execution, it is
  # compared to Time.now to determine how many further code execution
  # attempts remain
  #
  # @param [Integer] attempts The total amount of attempts to execute that we
  # are willing to allow
  #
  # @return [Google::Apis::ComputeV1::Operation]
  #
  # @raise [Google::Apis::ServerError] An error occurred on the server and the request can be retried
  # @raise [Google::Apis::ClientError] The request is invalid and should not be retried without modification
  # @raise [Google::Apis::AuthorizationError] Authorization is required
  def delete_firewall(name)
    operation = @compute.delete_firewall(@options[:gce_project], name)
    @compute.wait_global_operation(@options[:gce_project], operation.name)
  end
end
