# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Beaker::GoogleComputeHelper do
  let(:logger) { instance_double(Beaker::Logger) }
  let(:base_options) { { logger: logger, gce_project: 'test-project', gce_ports: [] } }

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

  describe 'initialization validation' do
    context 'when project is not provided' do
      let(:options) { base_options.merge(gce_project: nil) }

      it 'raises an error' do
        expect do
          described_class.new(options)
        end.to raise_error('You must specify a gce_project for Google Compute Engine instances!')
      end
    end

    context 'when project is provided' do
      let(:options) { base_options }

      it 'does not raise an error' do
        mock_google_services

        expect do
          described_class.new(options)
        end.not_to raise_error
      end
    end
  end

  describe 'port validation' do
    context 'when port format is invalid' do
      let(:options) { base_options.merge(gce_ports: ['22']) }

      it 'raises an error' do
        expect do
          described_class.new(options)
        end.to raise_error(%r{Invalid format for port 22. Should be 'port/proto'})
      end
    end

    context 'when port protocol is invalid' do
      let(:options) { base_options.merge(gce_ports: ['22/invalid']) }

      it 'raises an error' do
        expect do
          described_class.new(options)
        end.to raise_error(%r{Invalid value 'invalid' for protocol in '22/invalid'. Must be one of})
      end
    end

    context 'when port format is valid' do
      let(:options) { base_options.merge(gce_ports: ['22/tcp', '80/tcp']) }

      it 'does not raise an error' do
        mock_google_services

        expect do
          described_class.new(options)
        end.not_to raise_error
      end
    end

    context 'when all valid protocols are used' do
      let(:valid_protocols) { described_class::VALID_PROTOS }

      before do
        mock_google_services
      end

      it 'accepts all valid protocols' do
        valid_protocols.each do |proto|
          options = base_options.merge(gce_ports: ["80/#{proto}"])
          expect { described_class.new(options) }.not_to raise_error
        end
      end
    end
  end
end
