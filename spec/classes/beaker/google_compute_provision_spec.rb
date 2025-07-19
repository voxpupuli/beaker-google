# frozen_string_literal: true

require 'spec_helper'
require_relative '../../support/google_compute_shared_setup'

RSpec.describe Beaker::GoogleCompute do
  include GoogleComputeSharedSetup

  setup_google_compute_mocks
  setup_test_hosts
  setup_test_options

  subject(:google_compute) { described_class.new(hosts, options) }

  describe '#provision' do
    include FakeFS::SpecHelpers

    before do
      allow(SecureRandom).to receive(:hex).and_return('abcd1234')

      # Set up fake SSH keys for provision tests
      private_key_path = File.join(Dir.home, '.ssh', 'google_compute_engine')
      public_key_path = "#{private_key_path}.pub"

      FileUtils.mkdir_p(File.dirname(private_key_path))
      File.write(private_key_path, 'private key content')
      File.write(public_key_path, 'ssh-rsa AAAAB3NzaC1yc2E...')

      # Mock external SSH operations that are inherited from parent class
      # These are only needed for provision tests and perform external SSH operations
      # rubocop:disable RSpec/SubjectStub
      allow(google_compute).to receive(:copy_ssh_to_root)
      allow(google_compute).to receive(:enable_root_login)
      # rubocop:enable RSpec/SubjectStub
    end

    it 'provisions all hosts successfully' do
      expect { google_compute.provision }.not_to raise_error
    end

    it 'sets vmhostname for all hosts' do
      google_compute.provision
      hosts.each do |host|
        expect(host['vmhostname']).to match(/beaker-abcd1234-.*/)
      end
    end

    it 'sets IP address for all hosts' do
      google_compute.provision
      hosts.each do |host|
        expect(host['ip']).to eq('1.2.3.4')
      end
    end
  end

  describe '#cleanup' do
    before do
      google_compute.instance_variable_set(:@external_firewall_name, 'external-fw')
      google_compute.instance_variable_set(:@internal_firewall_name, 'internal-fw')
      primary_host['vmhostname'] = 'vm-host1'
      secondary_host['vmhostname'] = 'vm-host2'
    end

    it 'cleans up resources' do
      expect { google_compute.cleanup }.not_to raise_error
    end
  end
end
