# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Beaker::GoogleComputeHelper do
  context 'when testing constants and defaults' do
    let(:base_options) do
      {
        gce_project: 'test-project',
        gce_zone: 'us-central1-a',
        gce_network: 'default',
        logger: instance_double(Beaker::Logger, debug: nil, info: nil, warn: nil, error: nil),
      }
    end

    describe 'Google Compute Helper constants' do
      it 'defines AUTH_URL constant' do
        expect(described_class::AUTH_URL).to eq('https://www.googleapis.com/auth/compute')
      end

      it 'defines API_VERSION constant' do
        expect(described_class::API_VERSION).to eq('v1')
      end

      it 'defines BASE_URL constant' do
        expect(described_class::BASE_URL).to eq('https://www.googleapis.com/compute/v1/projects/')
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

      it 'defines SLEEPWAIT constant' do
        expect(described_class::SLEEPWAIT).to eq(5)
      end

      it 'defines valid protocols' do
        expect(described_class::VALID_PROTOS).to eq(%w[tcp udp icmp esp ah ipip sctp])
          .and be_frozen
      end

      it 'defines GCP auth scopes structure' do
        auth_scopes = described_class::GCP_AUTH_SCOPE

        expect(auth_scopes).to be_an(Array).and be_frozen.and have_attributes(length: 2)
          .and include('https://www.googleapis.com/auth/compute')
          .and include('https://www.googleapis.com/auth/cloud-platform.read-only')
      end
    end

    describe 'Google Compute constants' do
      it 'defines Windows image projects' do
        expect(Beaker::GoogleCompute::WINDOWS_IMAGE_PROJECT).to eq(%w[windows-cloud windows-sql-cloud])
          .and be_frozen
      end
    end
  end
end
