# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Beaker::GoogleCompute do
  context 'when testing constants and defaults' do
    let(:base_options) do
      {
        gce_project: 'test-project',
        gce_zone: 'us-central1-a',
        gce_network: 'default',
        gce_ports: ['80/tcp', '443/tcp'],
        logger: instance_double(Beaker::Logger),
      }
    end

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

    describe 'environment variable handling' do
      it 'uses default zone constant when environment variable is not set' do
        # Test that the gem uses the default zone constant when no environment variable is set
        expect(Beaker::GoogleComputeHelper::DEFAULT_ZONE_NAME).to eq('us-central1-a')
      end

      it 'uses default zone from options when initialized' do
        # Test that the helper uses the default zone from options when initialized
        helper = Beaker::GoogleComputeHelper.new(base_options)
        expect(helper.default_zone).to eq('us-central1-a')
      end

      it 'uses default network constant when environment variable is not set' do
        # Test that the gem uses the default network constant when no environment variable is set
        expect(Beaker::GoogleComputeHelper::DEFAULT_NETWORK_NAME).to eq('default')
      end

      it 'uses default network from options when initialized' do
        # Test that the helper uses the default network from options when initialized
        helper = Beaker::GoogleComputeHelper.new(base_options)
        expect(helper.default_network).to eq('default')
      end

      it 'processes port configuration through actual gem logic' do
        # Test that the gem processes port configuration correctly
        helper_with_ports = Beaker::GoogleComputeHelper.new(base_options.merge(gce_ports: ['80/tcp', '443/tcp',
                                                                                           '22/tcp',]))
        expect(helper_with_ports.options[:gce_ports]).to eq(['80/tcp', '443/tcp', '22/tcp'])
      end
    end

    describe 'zone and region utilities' do
      let(:zone_test_cases) do
        {
          'us-central1-a' => 'us-central1',
          'us-west1-b' => 'us-west1',
          'europe-west1-c' => 'europe-west1',
          'asia-east1-a' => 'asia-east1',
        }
      end

      before do
        allow(ENV).to receive(:fetch).with('BEAKER_gce_network', anything).and_return('default')
        allow(ENV).to receive(:fetch).with('BEAKER_gce_subnetwork', anything).and_return(nil)
        allow(ENV).to receive(:fetch).with('BEAKER_gce_ports', anything).and_return('')
        allow(ENV).to receive(:[]).with('BEAKER_gce_project').and_return(nil)
        allow(ENV).to receive(:[]).with('GOOGLE_APPLICATION_CREDENTIALS').and_return(nil)
      end

      it 'extracts region from zone using default_region method' do
        allow(ENV).to receive(:fetch).with('BEAKER_gce_zone', anything).and_return('us-central1-a')

        # Test the actual default_region method from the gem
        helper = Beaker::GoogleComputeHelper.new(base_options.merge(gce_zone: 'us-central1-a'))
        expect(helper.default_region).to eq('us-central1')
      end

      it 'handles different zone formats' do
        zone_test_cases.each do |zone, expected_region|
          allow(ENV).to receive(:fetch).with('BEAKER_gce_zone', anything).and_return(zone)
          helper = Beaker::GoogleComputeHelper.new(base_options.merge(gce_zone: zone))
          expect(helper.default_region).to eq(expected_region)
        end
      end
    end

    describe 'connection preferences' do
      it 'prefers IP connections' do
        # Test the actual connection_preference method from the gem
        google_compute = described_class.new([], base_options)
        expect(google_compute.connection_preference(nil)).to eq([:ip])
      end
    end

    describe 'Windows image detection' do
      it 'uses Windows image project constants' do
        # Test the actual Windows image project constants from the gem
        expect(Beaker::GoogleCompute::WINDOWS_IMAGE_PROJECT).to include('windows-cloud')
          .and include('windows-sql-cloud')
      end
    end

    private

    def mock_google_services
      compute = instance_double(Google::Apis::ComputeV1::ComputeService)
      oslogin = instance_double(Google::Apis::OsloginV1::CloudOSLoginService)
      auth = instance_double(Google::Auth::ServiceAccountCredentials)
      client_options = instance_double(Google::Apis::ClientOptions)

      allow(Google::Apis::ComputeV1::ComputeService).to receive(:new).and_return(compute)
      allow(Google::Apis::OsloginV1::CloudOSLoginService).to receive(:new).and_return(oslogin)
      allow(Google::Auth::ServiceAccountCredentials).to receive(:make_creds).and_return(auth)
      allow(Google::Auth::UserRefreshCredentials).to receive(:make_creds).and_return(auth)
      allow(Google::Auth).to receive(:get_application_default).and_return(auth)

      allow(compute).to receive(:authorization=)
      allow(oslogin).to receive(:authorization=)

      allow(client_options).to receive(:application_name=)
      allow(client_options).to receive(:application_version=)
      allow(Google::Apis::ClientOptions).to receive(:default).and_return(client_options)
    end
  end
end
