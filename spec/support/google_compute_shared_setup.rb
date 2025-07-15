# frozen_string_literal: true

# Shared setup for Google Compute tests to avoid multiple memoized helpers
module GoogleComputeSharedSetup
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def setup_google_compute_mocks
      let(:mock_gce_helper) { instance_double(Beaker::GoogleComputeHelper) }
      let(:mock_network) { MockNetwork.new }
      let(:mock_machine_type) { MockMachineType.new }
      let(:mock_image) { MockImage.new }
      let(:mock_instance) do
        instance_double(Google::Apis::ComputeV1::Instance).tap do |instance|
          allow(instance).to receive(:network_interfaces)
            .and_return([
                          instance_double(Google::Apis::ComputeV1::NetworkInterface).tap do |interface|
                            allow(interface).to receive(:access_configs)
                              .and_return([
                                            instance_double(Google::Apis::ComputeV1::AccessConfig).tap do |config|
                                              allow(config).to receive(:nat_ip).and_return('1.2.3.4')
                                            end,
                                          ])
                          end,
                        ])
        end
      end
      let(:mock_operation) do
        instance_double(Google::Apis::ComputeV1::Operation).tap do |operation|
          allow(operation).to receive(:error).and_return(nil)
        end
      end

      let(:logger) { instance_double(Beaker::Logger, debug: nil, info: nil, warn: nil, error: nil) }

      before do
        # Mock the GoogleComputeHelper initialization to avoid authentication
        allow(Beaker::GoogleComputeHelper).to receive(:new).and_return(mock_gce_helper)

        # Mock all the GoogleComputeHelper methods
        allow(mock_gce_helper).to receive_messages(
          get_network: mock_network,
          get_machine_type: mock_machine_type,
          get_image: mock_image,
          get_latest_image_from_family: mock_image,
          get_instance: mock_instance,
          create_firewall: mock_operation,
          delete_firewall: mock_operation,
          create_instance: mock_operation,
          delete_instance: mock_operation,
          add_instance_tag: mock_operation,
          set_metadata_on_instance: mock_operation,
          options: options,
        )

        # Set up environment variables for testing
        allow(ENV).to receive(:fetch).and_call_original
        allow(ENV).to receive(:fetch).with('BEAKER_gce_machine_type', anything).and_return('n1-standard-1')
        allow(ENV).to receive(:fetch).with('BEAKER_gce_ssh_private_key',
                                           anything).and_return(File.join(Dir.home, '.ssh', 'google_compute_engine'))
        allow(ENV).to receive(:fetch).with('BEAKER_gce_zone', anything).and_return('us-central1-a')
        allow(ENV).to receive(:fetch).with('BEAKER_gce_network', anything).and_return('default')
        allow(ENV).to receive(:fetch).with('BEAKER_gce_subnetwork', anything).and_return(nil)
        allow(ENV).to receive(:fetch).with('BEAKER_gce_ports', anything).and_return('80/tcp,443/tcp')
        allow(ENV).to receive(:[]).with('BEAKER_gce_project').and_return('test-project')
        allow(ENV).to receive(:[]).with('BEAKER_gce_ssh_public_key').and_return(nil)
        allow(ENV).to receive(:[]).with('BEAKER_gce_ssh_private_key').and_return(nil)

        # Mock the image disk size
        allow(mock_image).to receive(:disk_size_gb).and_return(20)
      end
    end

    def setup_test_hosts
      let(:primary_host) do
        {
          'name' => 'test-host-1',
          'user' => 'root',
          'options' => { 'ssh' => { 'keys' => [] } },
          'gce_machine_type' => 'n1-standard-1',
          :image => 'ubuntu-1804-lts',
          'volume_size' => nil,
          'disable_root_ssh' => nil,
        }.tap do |host|
          # Add methods needed by the gem
          def host.close; end

          def host.name
            self['name']
          end

          def host.options
            self['options']
          end
        end
      end

      let(:secondary_host) do
        {
          'name' => 'test-host-2',
          'user' => 'root',
          'options' => { 'ssh' => { 'keys' => [] } },
          'gce_machine_type' => 'n1-standard-1',
          :image => 'ubuntu-1804-lts',
          'volume_size' => nil,
          'disable_root_ssh' => nil,
        }.tap do |host|
          # Add methods needed by the gem
          def host.close; end

          def host.name
            self['name']
          end

          def host.options
            self['options']
          end
        end
      end

      let(:hosts) { [primary_host, secondary_host] }
    end

    def setup_test_options
      let(:options) do
        {
          gce_project: 'test-project',
          gce_zone: 'us-central1-a',
          gce_network: 'default',
          gce_ports: ['80/tcp', '443/tcp'],
          logger: logger,
        }
      end
    end
  end
end
