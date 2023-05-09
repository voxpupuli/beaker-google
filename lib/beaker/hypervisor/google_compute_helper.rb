# frozen_string_literal: true

require 'google/apis/compute_v1'
require 'google/apis/oslogin_v1'
require 'googleauth'
require 'json'
require 'time'
require 'ostruct'

# TODO: Figure out what to do about the timeout thing
#   TODO: Implement Google::Apis::RequestOptions on all calls (In lib/google/apis/options.rb)

# Beaker helper module for doing API level Google Compute Engine interaction.
class Beaker::GoogleComputeHelper
  class GoogleComputeError < StandardError
  end

  SLEEPWAIT = 5

  AUTH_URL = 'https://www.googleapis.com/auth/compute'
  API_VERSION = 'v1'
  BASE_URL = "https://www.googleapis.com/compute/#{API_VERSION}/projects/"
  DEFAULT_ZONE_NAME = 'us-central1-a'
  DEFAULT_MACHINE_TYPE = 'e2-standard-4'
  DEFAULT_NETWORK_NAME = 'default'

  GCP_AUTH_SCOPE = [
    Google::Apis::ComputeV1::AUTH_COMPUTE,
    Google::Apis::OsloginV1::AUTH_CLOUD_PLATFORM_READ_ONLY,
  ].freeze

  ##
  # Create a new instance of the Google Compute Engine helper object
  #
  def initialize(options)
    @options = options
    @logger = options[:logger]

    set_client(Beaker::Version::STRING)

    # ::Google::Apis.logger = ::Logger.new(::STDERR)
    # ::Google::Apis.logger.level = ::Logger::DEBUG
    # ::Google::Apis.logger.level = ::Logger::WARN

    @options[:gce_project] = ENV['BEAKER_gce_project'] if ENV['BEAKER_gce_project']

    @options[:gce_zone] = ENV.fetch('BEAKER_gce_zone', DEFAULT_ZONE_NAME)
    @options[:gce_network] = ENV.fetch('BEAKER_gce_network', DEFAULT_NETWORK_NAME)
    @options[:gce_subnetwork] = ENV.fetch('BEAKER_gce_subnetwork', nil)

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
      @options[:gce_subnetwork] ||= @compute.get_subnetwork(@options[:gce_project], default_region, 'default').name
    elsif @options[:gce_subnetwork].nil?
      # No subnet set, get the first subnet in our current region for the network
      subnetwork = @compute.get_network(@options[:gce_project], network_name).subnetworks[0]
      m = %r{.*/subnetworks/(?<subnetwork_name>.*)\Z}.match subnetwork
      raise "Unable to find a subnetwork in provided network #{network_name}" if m.nil?

      @options[:gce_subnetwork] = m['subnetwork_name']
    end
    @options[:gce_subnetwork]
  end

  ##
  # Set the user-agent information for the application.
  #
  # @param version The version number of Beaker currently running
  def set_client(version)
    ::Google::Apis::ClientOptions.default.application_name = 'beaker-google'
    ::Google::Apis::ClientOptions.default.application_version = version
  end

  ##
  # Creates an authentication object to use in the various Google APIs
  #
  # This method currently supports using application credentials via the
  # GOOGLE_APPLICATION_CREDENTIALS environment variable, and application default
  # credentials.
  #
  # @return [Google::Auth::UserRefreshCredentials|Google::Auth::ServiceAccountCredentials]
  #    Authorization object to pass to Google APIs
  def authenticate
    if ENV['GOOGLE_APPLICATION_CREDENTIALS']
      ::Google::Auth::ServiceAccountCredentials.from_env(scope: GCP_AUTH_SCOPE)
    else
      # Fall back to default application auth
      ::Google::Auth.get_application_default(GCP_AUTH_SCOPE)
    end
  end

  ##
  # Find the correct image object for a given project and name
  #
  # @param [String] image_project The project that owns the requested image
  #
  # @param [String] name The name of the image in the project. This must
  #   be the exact name of the image
  #
  # @return [Google::Apis::ComputeV1::Image]
  #
  # @raise [Google::Apis::ServerError] An error occurred on the server and the request can be retried
  # @raise [Google::Apis::ClientError] The request is invalid and should not be retried without modification
  # @raise [Google::Apis::AuthorizationError] Authorization is required
  def get_image(project, name)
    @compute.get_image(project, name)
  end

  ##
  # Find the latest non-deprecated image in the given project and family
  #
  # @param [String] image_project The project that owns the requested image
  #
  # @param [String] family The name of the image family
  #
  # @return [Google::Apis::ComputeV1::Image]
  #
  # @raise [Google::Apis::ServerError] An error occurred on the server and the request can be retried
  # @raise [Google::Apis::ClientError] The request is invalid and should not be retried without modification
  # @raise [Google::Apis::AuthorizationError] Authorization is required
  def get_latest_image_from_family(image_project, family)
    @compute.get_image_from_family(image_project, family)
  end

  ##
  # Determines the Google Compute machineType object based upon the selected
  # gce_machine_type option
  #
  # @param [String] type_name The name of the type to get
  #
  # @return [Google::Apis::ComputeV1::MachineType]
  #
  # @raise [Google::Apis::ServerError] An error occurred on the server and the request can be retried
  # @raise [Google::Apis::ClientError] The request is invalid and should not be retried without modification
  # @raise [Google::Apis::AuthorizationError] Authorization is required
  def get_machine_type(type_name = DEFAULT_MACHINE_TYPE)
    @compute.get_machine_type(@options[:gce_project], default_zone, type_name)
  end

  ##
  # Determines the Google Compute network object in use for the current connection
  #
  # @return [Google::Apis::ComputeV1::Network]
  #
  # @raise [Google::Apis::ServerError] An error occurred on the server and the request can be retried
  # @raise [Google::Apis::ClientError] The request is invalid and should not be retried without modification
  # @raise [Google::Apis::AuthorizationError] Authorization is required
  def get_network(network_name = default_network)
    @compute.get_network(@options[:gce_project], network_name)
  end

  ##
  # Determines a list of existing Google Compute instances
  #
  # @return [Array[Google::Apis::ComputeV1::Instance]]
  #
  # @raise [Google::Apis::ServerError] An error occurred on the server and the request can be retried
  # @raise [Google::Apis::ClientError] The request is invalid and should not be retried without modification
  # @raise [Google::Apis::AuthorizationError] Authorization is required
  def list_instances
    @compute.list_instances(@options[:gce_project], default_zone).items
  end

  ##
  # Determines a list of existing Google Compute disks
  #
  # @param [Integer] start The time when we started code execution, it is
  # compared to Time.now to determine how many further code execution
  # attempts remain
  #
  # @return [Array[Google::Apis::ComputeV1::Disk]]
  #
  # @raise [Google::Apis::ServerError] An error occurred on the server and the request can be retried
  # @raise [Google::Apis::ClientError] The request is invalid and should not be retried without modification
  # @raise [Google::Apis::AuthorizationError] Authorization is required
  def list_disks
    @compute.list_disks(@options[:gce_project], default_zone).items
  end

  ##
  # Determines a list of existing Google Compute firewalls
  #
  # @return [Array[Google::Apis::ComputeV1::Firewall]]
  #
  # @raise [Google::Apis::ServerError] An error occurred on the server and the request can be retried
  # @raise [Google::Apis::ClientError] The request is invalid and should not be retried without modification
  # @raise [Google::Apis::AuthorizationError] Authorization is required
  def list_firewalls
    @compute.list_firewalls(@options[:gce_project],
                            filter: 'name != default-allow-internal AND name != default-ssh').items
  end

  ##
  # Create a Google Compute firewall
  #
  # @param [String] name The name of the firewall to create
  #
  # @param [::Google::Apis::ComputeV1::Network] network The Google Compute networkin which to create
  # the firewall
  #
  # @return [Google::Apis::ComputeV1::Operation]
  #
  # @raise [Google::Apis::ServerError] An error occurred on the server and the request can be retried
  # @raise [Google::Apis::ClientError] The request is invalid and should not be retried without modification
  # @raise [Google::Apis::AuthorizationError] Authorization is required
  def create_firewall(name, network)
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

  ##
  # Add a taget_tag to an existing firewall
  #
  # @param [String] the name of the firewall to update
  #
  # @ param [String] tag The tag to add to the firewall
  #
  # @return [Google::Apis::ComputeV1::Operation]
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

  ##
  # Create a Google Compute disk
  #
  # @param [String] name The name of the disk to create
  #
  # @param [String] img The existing disk image to clone for this image
  #   or nil to create a blank disk
  #
  # @return [Google::Apis::ComputeV1::Operation]
  #
  # @raise [Google::Apis::ServerError] An error occurred on the server and the request can be retried
  # @raise [Google::Apis::ClientError] The request is invalid and should not be retried without modification
  # @raise [Google::Apis::AuthorizationError] Authorization is required
  def create_disk(name, size, img = nil)
    new_disk = ::Google::Apis::ComputeV1::Disk.new(
      name: name,
      size_gb: size,
      source_image: img,
    )
    operation = @compute.insert_disk(@options[:gce_project], @options[:gce_zone], new_disk)
    @compute.wait_zone_operation(@options[:gce_project], @options[:gce_zone], operation.name)
  end

  ##
  # Create a Google Compute instance
  #
  # @param [String] name The name of the instance to create
  #
  # @param [Google::Apis::ComputeV1::Image] img The Google Compute image to use for instance creation
  #
  # @param [Google::Apis::ComputeV1::MachineType] machine_type The Google Compute Machine Type
  #
  # @param [Integer] disk_size The size of the boot disk for the new instance. Must be equal to or
  #   greater than the image disk's size
  #
  # @param [String] hostname The custom hostname to set in the OS of the instance
  #
  # @return [Google::Apis::ComputeV1::Operation]
  #
  # @raise [Google::Apis::ServerError] An error occurred on the server and the request can be retried
  # @raise [Google::Apis::ClientError] The request is invalid and should not be retried without modification
  # @raise [Google::Apis::AuthorizationError] Authorization is required
  def create_instance(name, img, machine_type, disk_size, hostname)
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

    # use custom hostname if specified
    if hostname && ENV.fetch('BEAKER_set_gce_hostname', false)
      # The google api requires an FQDN for the custom hostname
      hostname.include? '.' ? valid_hostname = hostname : valid_hostname = hostname + '.beaker.test' 

      new_instance = ::Google::Apis::ComputeV1::Instance.new(
        machine_type: machine_type.self_link,
        name: name,
        disks: [disk_params],
        network_interfaces: [network_interface],
        tags: tags,
        hostname: valid_hostname,
      )
    else
      new_instance = ::Google::Apis::ComputeV1::Instance.new(
        machine_type: machine_type.self_link,
        name: name,
        disks: [disk_params],
        network_interfaces: [network_interface],
        tags: tags,
      )
    end
    operation = @compute.insert_instance(@options[:gce_project], @options[:gce_zone], new_instance)
    @compute.wait_zone_operation(@options[:gce_project], @options[:gce_zone], operation.name)
  end

  ##
  # Get the named instace from Google Compute Image
  #
  # @param [String] name The name of the instance
  #
  # @return [Google::Apis::ComputeV1::Instance]
  #
  # @raise [Google::Apis::ServerError] An error occurred on the server and the request can be retried
  # @raise [Google::Apis::ClientError] The request is invalid and should not be retried without modification
  # @raise [Google::Apis::AuthorizationError] Authorization is required
  def get_instance(name)
    @compute.get_instance(@options[:gce_project], @options[:gce_zone], name)
  end

  ##
  # Set key/value metadata pairs to a Google Compute instance
  #
  # This function replaces any existing items in the metadata hash!
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

  ##
  # Delete a Google Compute instance
  #
  # @param [String] name The name of the instance to delete
  #
  # @return [Google::Apis::ComputeV1::Operation]
  #
  # @raise [Google::Apis::ServerError] An error occurred on the server and the request can be retried
  # @raise [Google::Apis::ClientError] The request is invalid and should not be retried without modification
  # @raise [Google::Apis::AuthorizationError] Authorization is required
  def delete_instance(name)
    operation = @compute.delete_instance(@options[:gce_project], default_zone, name)
    @compute.wait_zone_operation(@options[:gce_project], @options[:gce_zone], operation.name)
  end

  ##
  # Delete a Google Compute disk
  #
  # @param [String] name The name of the disk to delete
  #
  # @return [Google::Apis::ComputeV1::Operation]
  #
  # @raise [Google::Apis::ServerError] An error occurred on the server and the request can be retried
  # @raise [Google::Apis::ClientError] The request is invalid and should not be retried without modification
  # @raise [Google::Apis::AuthorizationError] Authorization is required
  def delete_disk(name)
    operation = @compute.delete_disk(@options[:gce_project], default_zone, name)
    @compute.wait_zone_operation(@options[:gce_project], @options[:gce_zone], operation.name)
  end

  ##
  # Delete a Google Compute firewall
  #
  # @param [String] name The name of the firewall to delete
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
