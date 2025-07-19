# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Beaker::GoogleCompute do
  include FakeFS::SpecHelpers

  subject(:google_compute) do
    mock_google_services
    described_class.new(hosts, options)
  end

  let(:logger) { instance_double(Beaker::Logger) }
  let(:hosts) { [] }
  let(:options) { { logger: logger, gce_project: 'test-project', gce_ports: [] } }

  def mock_google_services
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

  describe '#find_google_ssh_private_key' do
    let(:default_private_key) { File.join(Dir.home, '.ssh', 'google_compute_engine') }

    context 'when default key exists' do
      before do
        FileUtils.mkdir_p(File.dirname(default_private_key))
        File.write(default_private_key, 'private key content')
      end

      it 'returns the default private key path' do
        expect(google_compute.find_google_ssh_private_key).to eq(default_private_key)
      end
    end

    context 'when private key does not exist' do
      it 'raises an error' do
        expect { google_compute.find_google_ssh_private_key }.to raise_error(/Could not find GCE Private SSH key/)
      end
    end
  end

  describe '#find_google_ssh_private_key with custom key' do
    subject(:google_compute) do
      mock_google_services
      described_class.new(hosts, options.merge(gce_ssh_private_key: custom_private_key))
    end

    let(:custom_private_key) { '/custom/path/to/key' }

    context 'when custom key is specified in options' do
      before do
        FileUtils.mkdir_p(File.dirname(custom_private_key))
        File.write(custom_private_key, 'private key content')
      end

      it 'returns the custom private key path' do
        expect(google_compute.find_google_ssh_private_key).to eq(custom_private_key)
      end
    end
  end

  describe '#find_google_ssh_public_key' do
    subject(:google_compute) do
      mock_google_services
      described_class.new(hosts, options)
    end

    context 'when public key exists' do
      let(:private_key) { '/path/to/private_key' }
      let(:public_key) { '/path/to/private_key.pub' }

      before do
        FileUtils.mkdir_p(File.dirname(private_key))
        File.write(private_key, 'private key content')
        File.write(public_key, 'public key content')
        # Set up the private key path in options for this test
        google_compute.instance_variable_get(:@options)[:gce_ssh_private_key] = private_key
      end

      it 'returns the public key path' do
        expect(google_compute.find_google_ssh_public_key).to eq(public_key)
      end
    end

    context 'when public key does not exist' do
      let(:private_key) { '/path/to/private_key' }

      before do
        FileUtils.mkdir_p(File.dirname(private_key))
        File.write(private_key, 'private key content')
        # Set up the private key path in options for this test
        google_compute.instance_variable_get(:@options)[:gce_ssh_private_key] = private_key
      end

      it 'raises an error' do
        expect { google_compute.find_google_ssh_public_key }.to raise_error(/Could not find GCE Public SSH key/)
      end
    end
  end
end
