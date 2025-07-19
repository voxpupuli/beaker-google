# frozen_string_literal: true

require 'spec_helper'
require_relative '../../support/google_compute_shared_setup'

RSpec.describe Beaker::GoogleCompute do
  include GoogleComputeSharedSetup

  setup_google_compute_mocks
  setup_test_hosts
  setup_test_options

  subject(:google_compute) { described_class.new(hosts, options) }

  describe '#initialize' do
    it 'initializes hosts' do
      expect(google_compute.instance_variable_get(:@hosts)).to eq(hosts)
    end

    it 'initializes options' do
      expect(google_compute.instance_variable_get(:@options)).to eq(options)
    end

    it 'initializes logger' do
      expect(google_compute.instance_variable_get(:@logger)).to eq(logger)
    end

    it 'initializes external firewall name' do
      expect(google_compute.instance_variable_get(:@external_firewall_name)).to eq('')
    end

    it 'initializes internal firewall name' do
      expect(google_compute.instance_variable_get(:@internal_firewall_name)).to eq('')
    end
  end

  describe '#connection_preference' do
    it 'returns IP preference' do
      expect(google_compute.connection_preference(primary_host)).to eq([:ip])
    end
  end

  describe 'constants' do
    it 'defines SLEEPWAIT constant' do
      expect(described_class::SLEEPWAIT).to eq(5)
    end

    it 'defines WINDOWS_IMAGE_PROJECT constant' do
      expect(described_class::WINDOWS_IMAGE_PROJECT).to eq(%w[windows-cloud windows-sql-cloud])
    end
  end
end
