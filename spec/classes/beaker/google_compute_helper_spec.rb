# frozen_string_literal: true

# Add mutex_m requirement for Ruby 3.4.0 compatibility
begin
  require 'mutex_m'
rescue LoadError
  # mutex_m is not available on all Ruby versions
end

# Require core dependencies
require 'rspec'
require 'rspec/its'
require 'fakefs/spec_helpers'

# Require beaker first to establish the base classes
require 'beaker'

# Require the actual implementation before mocks to avoid conflicts
require 'beaker/hypervisor/google_compute_helper'

# Load shared mock classes
require File.join(File.dirname(__FILE__), '../../support/shared_mocks')

RSpec.describe Beaker::GoogleComputeHelper do
  subject(:google_compute_helper) { described_class.new(options) }

  let(:options) do
    {
      gce_project: 'test-project',
      gce_zone: 'us-central1-a',
      gce_network: 'default',
      gce_ports: ['80/tcp', '443/tcp'],
      logger: logger,
    }
  end

  let(:logger) { instance_double(Beaker::Logger, debug: nil, info: nil, warn: nil, error: nil) }

  # Stub Google API classes to avoid actual authentication
  before do
    client_options = instance_double(Google::Apis::ClientOptions)
    allow(client_options).to receive(:application_name=)
    allow(client_options).to receive(:application_version=)
    allow(Google::Apis::ClientOptions).to receive(:default).and_return(client_options)

    allow(Google::Auth::ServiceAccountCredentials).to receive(:from_env).and_return(
      instance_double(Google::Auth::ServiceAccountCredentials),
    )
    allow(Google::Auth).to receive(:get_application_default).and_return(
      instance_double(Google::Auth::ServiceAccountCredentials),
    )

    compute_service = instance_double(Google::Apis::ComputeV1::ComputeService)
    allow(compute_service).to receive(:authorization=)
    allow(Google::Apis::ComputeV1::ComputeService).to receive(:new).and_return(compute_service)

    oslogin_service = instance_double(Google::Apis::OsloginV1::CloudOSLoginService)
    allow(oslogin_service).to receive(:authorization=)
    allow(Google::Apis::OsloginV1::CloudOSLoginService).to receive(:new).and_return(oslogin_service)

    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:[]).with('GOOGLE_CLOUD_UNIVERSE_DOMAIN').and_return(nil)
    allow(ENV).to receive(:[]).with('GOOGLE_CLOUD_PROJECT').and_return(nil)
    allow(ENV).to receive(:[]).with('GCLOUD_PROJECT').and_return(nil)
    allow(ENV).to receive(:[]).with('GOOGLE_APPLICATION_CREDENTIALS').and_return(nil)
  end

  describe '#initialize' do
    context 'with environment variables' do
      before do
        allow(ENV).to receive(:[]).with('BEAKER_gce_project').and_return('env-project')
        allow(ENV).to receive(:fetch).with('BEAKER_gce_project', nil).and_return('env-project')
        allow(ENV).to receive(:fetch).with('BEAKER_gce_zone', 'us-central1-a').and_return('us-west1-a')
        allow(ENV).to receive(:fetch).with('BEAKER_gce_network', 'default').and_return('custom-network')
        allow(ENV).to receive(:fetch).with('BEAKER_gce_subnetwork', nil).and_return('custom-subnet')
        allow(ENV).to receive(:fetch).with('BEAKER_gce_ports', '').and_return('22/tcp,80/tcp')
      end

      it 'uses environment variables when available' do
        helper = described_class.new(options.merge(gce_project: nil))
        expect(helper.instance_variable_get(:@options)[:gce_project]).to eq('env-project')
      end
    end

    context 'without required project' do
      before do
        allow(ENV).to receive(:[]).with('BEAKER_gce_project').and_return(nil)
        allow(ENV).to receive(:fetch).with('BEAKER_gce_project', nil).and_return(nil)
      end

      it 'raises an error when gce_project is not provided' do
        expect do
          described_class.new(options.merge(gce_project: nil))
        end.to raise_error('You must specify a gce_project for Google Compute Engine instances!')
      end
    end

    context 'with invalid ports' do
      it 'raises an error for invalid port format' do
        expect do
          described_class.new(options.merge(gce_ports: ['invalid-port']))
        end.to raise_error(/Invalid format for port/)
      end

      it 'raises an error for invalid protocol' do
        expect do
          described_class.new(options.merge(gce_ports: ['80/invalid']))
        end.to raise_error(/Invalid value 'invalid' for protocol/)
      end
    end
  end

  describe '#client' do
    it 'sets the application name on Google API client options' do
      client_options = instance_spy(Google::Apis::ClientOptions)
      allow(Google::Apis::ClientOptions).to receive(:default).and_return(client_options)

      google_compute_helper.send(:client, Beaker::Version::STRING)

      expect(client_options).to have_received(:application_name=).with('beaker-google').at_least(:once)
    end

    it 'sets the application version on Google API client options' do
      client_options = instance_spy(Google::Apis::ClientOptions)
      allow(Google::Apis::ClientOptions).to receive(:default).and_return(client_options)

      google_compute_helper.send(:client, Beaker::Version::STRING)

      expect(client_options).to have_received(:application_version=).with(Beaker::Version::STRING).at_least(:once)
    end
  end

  describe '#authenticate' do
    context 'when GOOGLE_APPLICATION_CREDENTIALS environment variable is set' do
      let(:auth_double) { instance_double(Google::Auth::ServiceAccountCredentials) }

      before do
        allow(ENV).to receive(:[]).with('GOOGLE_APPLICATION_CREDENTIALS').and_return('/path/to/credentials.json')
        allow(Google::Auth::ServiceAccountCredentials).to receive(:from_env)
          .with(scope: described_class::GCP_AUTH_SCOPE)
          .and_return(auth_double)
      end

      it 'uses service account credentials from environment' do
        # Create a fresh instance to test authentication
        fresh_instance = described_class.allocate
        result = fresh_instance.send(:authenticate)
        expect(result).to eq(auth_double)
      end
    end

    context 'when GOOGLE_APPLICATION_CREDENTIALS is not set' do
      let(:auth_double) { instance_double(Google::Auth::ServiceAccountCredentials) }

      before do
        allow(ENV).to receive(:[]).with('GOOGLE_APPLICATION_CREDENTIALS').and_return(nil)
        allow(Google::Auth).to receive(:get_application_default)
          .with(described_class::GCP_AUTH_SCOPE)
          .and_return(auth_double)
      end

      it 'falls back to application default credentials' do
        # Create a fresh instance to test authentication
        fresh_instance = described_class.allocate
        result = fresh_instance.send(:authenticate)
        expect(result).to eq(auth_double)
      end
    end
  end

  describe '#default_zone' do
    it 'returns the configured zone from options' do
      expect(google_compute_helper.default_zone).to eq(options[:gce_zone])
    end
  end

  describe '#default_region' do
    it 'extracts region from zone in options' do
      expected_region = options[:gce_zone].split('-')[0..1].join('-')
      expect(google_compute_helper.default_region).to eq(expected_region)
    end
  end

  describe '#default_network' do
    it 'returns the configured network from options' do
      expect(google_compute_helper.default_network).to eq(options[:gce_network])
    end
  end

  describe 'API methods' do
    let(:compute_service) { instance_double(Google::Apis::ComputeV1::ComputeService) }

    before do
      google_compute_helper.instance_variable_set(:@compute, compute_service)
    end

    describe '#get_network' do
      it 'retrieves network information' do
        allow(compute_service).to receive(:get_network).and_return(MockNetwork.new)
        expect(google_compute_helper.get_network).to be_a(MockNetwork)
      end
    end

    describe '#get_machine_type' do
      it 'retrieves machine type information' do
        allow(compute_service).to receive(:get_machine_type).and_return(MockMachineType.new)
        expect(google_compute_helper.get_machine_type('n1-standard-1')).to be_a(MockMachineType)
      end
    end

    describe '#get_image' do
      it 'retrieves image information' do
        allow(compute_service).to receive(:get_image).and_return(MockImage.new)
        expect(google_compute_helper.get_image('test-project', 'test-image')).to be_a(MockImage)
      end
    end

    describe '#get_latest_image_from_family' do
      before do
        allow(compute_service).to receive(:get_image_from_family).and_return(MockImage.new)
      end

      it 'retrieves latest image from family' do
        expect(google_compute_helper.get_latest_image_from_family('test-project', 'test-family')).to be_a(MockImage)
      end
    end

    describe '#create_firewall' do
      let(:network) { instance_double(Google::Apis::ComputeV1::Network, self_link: 'network-link') }
      let(:result) do
        google_compute_helper.create_firewall(
          'test-firewall',
          network,
          allow: ['80/tcp'],
          source_ranges: ['0.0.0.0/0'],
          target_tags: ['test-tag'],
        )
      end

      before do
        allow(compute_service).to receive_messages(insert_firewall: MockOperation.new,
                                                   wait_global_operation: MockOperation.new)
      end

      it 'creates a firewall rule' do
        expect(result).to be_a(MockOperation)
      end
    end

    describe '#delete_firewall' do
      let(:result) { google_compute_helper.delete_firewall('test-firewall') }

      before do
        allow(compute_service).to receive_messages(delete_firewall: MockOperation.new,
                                                   wait_global_operation: MockOperation.new)
      end

      it 'deletes a firewall rule' do
        expect(result).to be_a(MockOperation)
      end
    end

    describe '#create_instance' do
      let(:image) { instance_double(Google::Apis::ComputeV1::Image, self_link: 'image-link') }
      let(:machine_type) { instance_double(Google::Apis::ComputeV1::MachineType, self_link: 'machine-link') }

      before do
        allow(compute_service).to receive_messages(
          get_network: MockNetwork.new,
          get_subnetwork: MockSubnetwork.new,
          insert_instance: MockOperation.new,
          wait_zone_operation: MockOperation.new,
        )
      end

      it 'creates an instance' do
        result = google_compute_helper.create_instance('test-instance', image, machine_type, 20, 'test-host')
        expect(result).to be_a(MockOperation)
      end
    end

    describe '#delete_instance' do
      it 'deletes an instance' do
        allow(compute_service).to receive_messages(delete_instance: MockOperation.new,
                                                   wait_zone_operation: MockOperation.new)
        result = google_compute_helper.delete_instance('test-instance')
        expect(result).to be_a(MockOperation)
      end
    end

    describe '#get_instance' do
      it 'retrieves instance information' do
        allow(compute_service).to receive(:get_instance).and_return(MockInstance.new)
        result = google_compute_helper.get_instance('test-instance')
        expect(result).to be_a(MockInstance)
      end
    end

    describe '#add_instance_tag' do
      before do
        allow(compute_service).to receive_messages(
          get_instance: MockInstance.new,
          set_instance_tags: MockOperation.new,
          wait_zone_operation: MockOperation.new,
        )
      end

      it 'adds a tag to an instance' do
        result = google_compute_helper.add_instance_tag('test-instance', 'new-tag')
        expect(result).to be_a(MockOperation)
      end
    end

    describe '#set_metadata_on_instance' do
      let(:metadata) { [{ key: 'test-key', value: 'test-value' }] }

      before do
        allow(compute_service).to receive_messages(
          get_instance: MockInstance.new,
          set_instance_metadata: MockOperation.new,
          wait_zone_operation: MockOperation.new,
        )
      end

      it 'sets metadata on an instance' do
        result = google_compute_helper.set_metadata_on_instance('test-instance', metadata)
        expect(result).to be_a(MockOperation)
      end
    end
  end

  describe 'error handling' do
    describe 'GoogleComputeError' do
      it 'defines a custom error class' do
        expect(Beaker::GoogleComputeHelper::GoogleComputeError).to be < StandardError
      end
    end
  end

  describe 'constants' do
    it 'defines AUTH_URL constant' do
      expect(described_class::AUTH_URL).to eq('https://www.googleapis.com/auth/compute')
    end

    it 'defines API_VERSION constant' do
      expect(described_class::API_VERSION).to eq('v1')
    end

    it 'defines DEFAULT_ZONE_NAME constant' do
      expect(described_class::DEFAULT_ZONE_NAME).to eq('us-central1-a')
    end

    it 'defines DEFAULT_MACHINE_TYPE constant' do
      expect(described_class::DEFAULT_MACHINE_TYPE).to eq('e2-standard-4')
    end

    it 'defines DEFAULT_NETWORK_NAME constant' do
      expect(described_class::DEFAULT_NETWORK_NAME).to eq('default')
    end

    it 'defines VALID_PROTOS constant' do
      expect(described_class::VALID_PROTOS).to eq(%w[tcp udp icmp esp ah ipip sctp])
        .and be_frozen
    end
  end
end
