# frozen_string_literal: true

require 'spec_helper'
require_relative '../../support/google_compute_shared_setup'

RSpec.describe Beaker::GoogleCompute do
  include GoogleComputeSharedSetup

  setup_google_compute_mocks
  setup_test_hosts
  setup_test_options

  subject(:google_compute) { described_class.new(hosts, options) }

  describe '#find_google_ssh_private_key' do
    include FakeFS::SpecHelpers

    let(:default_private_key) { File.join(Dir.home, '.ssh', 'google_compute_engine') }
    let(:custom_private_key) { '/custom/path/to/key' }

    context 'when default key exists' do
      before do
        FileUtils.mkdir_p(File.dirname(default_private_key))
        File.write(default_private_key, 'private key content')
      end

      it 'returns the default private key path' do
        expect(google_compute.find_google_ssh_private_key).to eq(default_private_key)
      end

      it 'sets the private key in options' do
        google_compute.find_google_ssh_private_key
        expect(google_compute.instance_variable_get(:@options)[:gce_ssh_private_key]).to eq(default_private_key)
      end
    end

    context 'when custom key is specified in options' do
      before do
        FileUtils.mkdir_p(File.dirname(custom_private_key))
        File.write(custom_private_key, 'private key content')
        google_compute.instance_variable_get(:@options)[:gce_ssh_private_key] = custom_private_key
      end

      it 'returns the custom private key path' do
        expect(google_compute.find_google_ssh_private_key).to eq(custom_private_key)
      end
    end

    context 'when private key does not exist' do
      it 'raises an error' do
        expect { google_compute.find_google_ssh_private_key }.to raise_error(/Could not find GCE Private SSH key/)
      end
    end
  end

  describe '#find_google_ssh_public_key' do
    include FakeFS::SpecHelpers

    let(:private_key) { '/path/to/private_key' }
    let(:public_key) { '/path/to/private_key.pub' }

    before do
      FileUtils.mkdir_p(File.dirname(private_key))
      File.write(private_key, 'private key content')
    end

    context 'when public key exists' do
      before do
        File.write(public_key, 'public key content')
        # Set up the private key path in options for this test
        google_compute.instance_variable_get(:@options)[:gce_ssh_private_key] = private_key
      end

      it 'returns the public key path' do
        expect(google_compute.find_google_ssh_public_key).to eq(public_key)
      end

      it 'sets the public key in options' do
        google_compute.find_google_ssh_public_key
        expect(google_compute.instance_variable_get(:@options)[:gce_ssh_public_key]).to eq(public_key)
      end
    end

    context 'when public key does not exist' do
      before do
        # Set up the private key path in options for this test
        google_compute.instance_variable_get(:@options)[:gce_ssh_private_key] = private_key
      end

      it 'raises an error' do
        expect { google_compute.find_google_ssh_public_key }.to raise_error(/Could not find GCE Public SSH key/)
      end
    end
  end
end
