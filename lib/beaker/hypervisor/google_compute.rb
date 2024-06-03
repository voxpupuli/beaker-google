# frozen_string_literal: true

require 'securerandom'

module Beaker
  # Beaker support for the Google Compute Engine.
  class GoogleCompute < Beaker::Hypervisor
    SLEEPWAIT = 5

    WINDOWS_IMAGE_PROJECT = %w[windows-cloud windows-sql-cloud].freeze

    # Do some reasonable sleuthing on the SSH public key for GCE

    ##
    # Try to find the private ssh key file
    #
    # @return [String] The file path for the private key file
    #
    # @raise [Error] if the private key can not be found
    def find_google_ssh_private_key
      private_keyfile = ENV.fetch('BEAKER_gce_ssh_public_key',
                                  File.join(Dir.home, '.ssh', 'google_compute_engine'))
      if @options[:gce_ssh_private_key] && !File.exist?(private_keyfile)
        private_keyfile = @options[:gce_ssh_private_key]
      end
      raise("Could not find GCE Private SSH key at '#{keyfile}'") unless File.exist?(private_keyfile)

      @options[:gce_ssh_private_key] = private_keyfile
      private_keyfile
    end

    ##
    # Try to find the public key file based on the location of the private key or provided data
    #
    # @return [String] The file path for the public key file
    #
    # @raise [Error] if the public key can not be found
    def find_google_ssh_public_key
      private_keyfile = find_google_ssh_private_key
      public_keyfile = private_keyfile << '.pub'
      public_keyfile = @options[:gce_ssh_public_key] if @options[:gce_ssh_public_key] && !File.exist?(public_keyfile)
      raise("Could not find GCE Public SSH key at '#{keyfile}'") unless File.exist?(public_keyfile)

      @options[:gce_ssh_public_key] = public_keyfile
      public_keyfile
    end

    # IP is the only way we can be sure to connect
    # TODO: This isn't being called
    # rubocop:disable Lint/UnusedMethodArgument
    def connection_preference(host)
      [:ip]
    end
    # rubocop:enable Lint/UnusedMethodArgument

    # Create a new instance of the Google Compute Engine hypervisor object
    #
    # @param [<Host>] google_hosts The Array of google hosts to provision, may
    # ONLY be of platforms /centos-*/, /debian-*/, /rhel-*/, /suse-*/. Only
    # supports the Google Compute provided templates.
    #
    # @param [Hash{Symbol=>String}] options The options hash containing
    # configuration values @option options [String] :gce_project The Google
    # Compute Project name to connect to
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
    def initialize(google_hosts, options)
      require 'beaker/hypervisor/google_compute_helper'

      super
      @options = options
      @logger = options[:logger]
      @hosts = google_hosts
      @external_firewall_name = ''
      @internal_firewall_name = ''
      @gce_helper = GoogleComputeHelper.new(options)
    end

    # Create and configure virtual machines in the Google Compute Engine,
    # including their associated disks and firewall rules
    def provision
      test_group_identifier = "beaker-#{SecureRandom.hex(4)}"

      # set firewall to open pe ports
      network = @gce_helper.get_network

      @external_firewall_name = "#{test_group_identifier}-external"

      # Always allow ssh from anywhere as it's needed for Beaker to run
      @gce_helper.create_firewall(
        @external_firewall_name,
        network,
        allow: @options[:gce_ports] + ['22/tcp'],
        source_ranges: ['0.0.0.0/0'],
        target_tags: [test_group_identifier],
      )

      @logger.debug("Created External Google Compute firewall #{@external_firewall_name}")

      # Create a firewall that opens everything between all the hosts in this test group
      @internal_firewall_name = "#{test_group_identifier}-internal"
      internal_ports = ['1-65535/tcp', '1-65535/udp', '-1/icmp']
      @gce_helper.create_firewall(
        @internal_firewall_name,
        network,
        allow: internal_ports,
        source_tags: [test_group_identifier],
        target_tags: [test_group_identifier],
      )
      @logger.debug("Created test group Google Compute firewall #{@internal_firewall_name}")

      @hosts.each do |host|
        machine_type_name = ENV.fetch('BEAKER_gce_machine_type', host['gce_machine_type'])
        raise "Must provide a machine type name in 'gce_machine_type'." if machine_type_name.nil?

        # Get the GCE machine type object for this host
        machine_type = @gce_helper.get_machine_type(machine_type_name)
        if machine_type.nil?
          raise "Unable to find machine type named #{machine_type_name} in region #{@compute.default_zone}"
        end

        # Find the image to use to create the new VM.
        # Either `image` or `family` must be set in the configuration. Accepted formats
        # for the image and family:
        #   - {project}/{image}
        #   - {project}/{family}
        #   - {image}
        #   - {family}
        #
        # If a {project} is not specified, default to the project provided in the
        # BEAKER_gce_project environment variable
        if host[:image]
          image_selector = host[:image]
          # Do we have a project name?
          if image_selector.include?('/')
            image_project, image_name = image_selector.split('/')[0..1]
          else
            image_project = @gce_helper.options[:gce_project]
            image_name = image_selector
          end
          img = @gce_helper.get_image(image_project, image_name)
          raise "Unable to find image #{image_name} from project #{image_project}" if img.nil?
        elsif host[:family]
          image_selector = host[:family]
          # Do we have a project name?
          if image_selector.include?('/')
            image_project, family_name = image_selector.split('/')
          else
            image_project = @gce_helper.options[:gce_project]
            family_name = image_selector
          end
          img = @gce_helper.get_latest_image_from_family(image_project, family_name)
          raise "Unable to find image in family #{family_name} from project #{image_project}" if img.nil?
        else
          raise('You must specify either :image or :family')
        end

        unique_host_id = "#{test_group_identifier}-#{generate_host_name}"

        boot_size = host['volume_size'] || img.disk_size_gb

        # The boot disk is created as part of the instance creation
        # TODO: Allow creation of other disks
        # disk = @gce_helper.create_disk(host["diskname"], img, size)
        # @logger.debug("Created Google Compute disk for #{host.name}: #{host["diskname"]}")

        # create new host name
        host['vmhostname'] = unique_host_id

        # add a new instance of the image
        operation = @gce_helper.create_instance(host['vmhostname'], img, machine_type, boot_size, host.name)
        unless operation.error.nil?
          raise "Unable to create Google Compute Instance #{
            host.name
          }: [#{
            operation.error.errors[0].code
          }] #{
            operation.error.errors[0].message
          }"
        end

        @logger.debug("Created Google Compute instance for #{host.name}: #{host['vmhostname']}")
        instance = @gce_helper.get_instance(host['vmhostname'])

        @gce_helper.add_instance_tag(host['vmhostname'], test_group_identifier)
        @logger.debug("Added network tag #{test_group_identifier} to instance")

        # Make sure we have a non root/Adminsitor user to log in as
        initial_user = if host['user'] == 'root' || host['user'] == 'Administrator' || host['user'].empty?
                         'google_compute'
                       else
                         host['user']
                       end

        # add metadata to instance, if there is any to set
        # mdata = format_metadata
        # TODO: Set a configuration option for this to allow disabeling oslogin
        mdata = [
          {
            key: 'ssh-keys',
            value: "#{initial_user}:#{File.read(find_google_ssh_public_key).strip}",
          },
          # For now oslogin needs to be disabled as there's no way to log in as root and it would
          # take too much work on beaker to add sudo support to everything
          {
            key: 'enable-oslogin',
            value: 'FALSE',
          },
        ]

        # Check for google's default windows images and turn on ssh if found
        if WINDOWS_IMAGE_PROJECT.include?(image_project)
          # Turn on SSH on GCP's default windows images
          mdata << {
            key: 'enable-windows-ssh',
            value: 'TRUE',
          }
          mdata << {
            key: 'sysprep-specialize-script-cmd',
            value: 'start /wait googet -noconfirm=true update && start /wait googet -noconfirm=true install google-compute-engine-ssh', # rubocop:disable Layout/LineLength
          }
          # Some versions of windows don't seem to add the OpenSSH directory to the path which prevents scp from working
          mdata << {
            key: 'sysprep-specialize-script-ps1',
            value: '[Environment]::SetEnvironmentVariable( "PATH", "$ENV:PATH;C:\Program Files\OpenSSH", [EnvironmentVariableTarget]::Machine )', # rubocop:disable Layout/LineLength
          }
        end
        unless mdata.empty?
          # Add the metadata to the host
          @gce_helper.set_metadata_on_instance(host['vmhostname'], mdata)
          @logger.debug("Added tags to Google Compute instance #{host.name}: #{host['vmhostname']}")
        end

        host['ip'] = instance.network_interfaces[0].access_configs[0].nat_ip

        if host['disable_root_ssh'] == true
          @logger.info('Not enabling root ssh as disable_root_ssh is true')
        else
          real_user = host['user']
          host['user'] = initial_user
          # Set the ssh private key we need to use
          host.options['ssh']['keys'] = [find_google_ssh_private_key]

          copy_ssh_to_root(host, @options)
          enable_root_login(host, @options)
          host['user'] = real_user
          # shut down connection, will reconnect on next exec
          host.close
        end

        @logger.debug("Instance ready: #{host['vmhostname']} for #{host.name}}")
      end
    end

    # Shutdown and destroy virtual machines in the Google Compute Engine,
    # including their associated disks and firewall rules
    def cleanup
      @gce_helper.delete_firewall(@external_firewall_name)
      @gce_helper.delete_firewall(@internal_firewall_name)

      @hosts.each do |host|
        # TODO: Delete any other disks attached during the instance creation
        @gce_helper.delete_instance(host['vmhostname'])
        @logger.debug("Deleted Google Compute instance #{host['vmhostname']} for #{host.name}")
      end
    end
  end
end
