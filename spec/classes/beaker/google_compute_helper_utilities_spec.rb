# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Beaker::GoogleComputeHelper do
  context 'when using utilities' do
    let(:logger) { instance_double(Beaker::Logger) }
    let(:base_options) { { logger: logger, gce_project: 'test-project' } }
    let(:helper) { described_class.new(base_options.merge(gce_zone: 'us-central1-a')) }

    before do
      # Mock the authentication and service initialization
      allow(Google::Auth).to receive(:get_application_default).and_return(double)

      compute_service = double
      allow(compute_service).to receive(:authorization=)
      allow(Google::Apis::ComputeV1::ComputeService).to receive(:new).and_return(compute_service)

      oslogin_service = double
      allow(oslogin_service).to receive(:authorization=)
      allow(Google::Apis::OsloginV1::CloudOSLoginService).to receive(:new).and_return(oslogin_service)

      client_options = double
      allow(client_options).to receive(:application_name=)
      allow(client_options).to receive(:application_version=)
      allow(Google::Apis::ClientOptions).to receive(:default).and_return(client_options)
    end

    describe 'region extraction' do
      let(:zone_test_cases) do
        {
          'us-central1-a' => 'us-central1',
          'us-west1-b' => 'us-west1',
          'europe-west1-c' => 'europe-west1',
          'asia-east1-a' => 'asia-east1',
        }
      end

      it 'extracts region from zone using default_region method' do
        expect(helper.default_region).to eq('us-central1')
      end

      it 'handles different zone formats' do
        zone_test_cases.each do |zone, expected_region|
          helper_with_zone = described_class.allocate
          helper_with_zone.instance_variable_set(:@options, base_options.merge(gce_zone: zone))
          expect(helper_with_zone.send(:default_region)).to eq(expected_region)
        end
      end
    end

    describe 'connection preferences' do
      it 'prefers IP connections' do
        google_compute = Beaker::GoogleCompute.new([], base_options)
        expect(google_compute.connection_preference(nil)).to eq([:ip])
      end
    end

    describe 'environment variable handling' do
      it 'uses default zone when environment variable is not set' do
        # Test the actual default zone constant
        expect(described_class::DEFAULT_ZONE_NAME).to eq('us-central1-a')
      end

      it 'uses default network when environment variable is not set' do
        # Test the actual default network constant
        expect(described_class::DEFAULT_NETWORK_NAME).to eq('default')
      end

      it 'processes port configuration through actual gem logic' do
        helper_with_ports = described_class.new(
          base_options.merge(gce_ports: ['80/tcp', '443/tcp', '22/tcp']),
        )
        expect(helper_with_ports.options[:gce_ports]).to eq(['80/tcp', '443/tcp', '22/tcp'])
      end

      it 'handles empty port configuration through actual gem logic' do
        helper_with_empty_ports = described_class.new(base_options.merge(gce_ports: []))
        expect(helper_with_empty_ports.options[:gce_ports]).to eq([])
      end
    end

    describe 'Windows image detection' do
      it 'identifies Windows images correctly' do
        expect(Beaker::GoogleCompute::WINDOWS_IMAGE_PROJECT).to include('windows-cloud')
          .and include('windows-sql-cloud')
      end

      it 'excludes non-Windows images' do
        expect(Beaker::GoogleCompute::WINDOWS_IMAGE_PROJECT).not_to include('ubuntu-os-cloud')
      end
    end
  end
end
