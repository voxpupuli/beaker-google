# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Beaker::GoogleComputeHelper do
  context 'when handling errors' do
    describe 'GoogleComputeError' do
      it 'can be raised with a custom message' do
        expect do
          raise Beaker::GoogleComputeHelper::GoogleComputeError, 'Custom error message'
        end.to raise_error(Beaker::GoogleComputeHelper::GoogleComputeError, 'Custom error message')
      end

      it 'inherits from StandardError' do
        expect(Beaker::GoogleComputeHelper::GoogleComputeError).to be < StandardError
      end
    end

    describe 'GoogleComputeHelper configuration errors' do
      let(:logger) { instance_double(Beaker::Logger) }
      let(:base_options) { { logger: logger } }

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

      it 'raises error when gce_project is missing' do
        expect do
          described_class.new(base_options.merge(gce_project: nil))
        end.to raise_error('You must specify a gce_project for Google Compute Engine instances!')
      end

      it 'passes validation when gce_project is provided' do
        options = base_options.merge(gce_project: 'test-project', gce_ports: [])

        expect do
          described_class.new(options)
        end.not_to raise_error
      end
    end

    describe 'GoogleComputeHelper port validation errors' do
      let(:logger) { instance_double(Beaker::Logger) }
      let(:base_options) { { logger: logger, gce_project: 'test-project' } }

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

      it 'raises error for invalid protocol' do
        options = base_options.merge(gce_ports: ['80/invalid'])

        expect do
          described_class.new(options)
        end.to raise_error(%r{Invalid value 'invalid' for protocol in '80/invalid'})
      end

      it 'raises error for invalid port format' do
        options = base_options.merge(gce_ports: ['invalid-port'])

        expect do
          described_class.new(options)
        end.to raise_error(/Invalid format for port invalid-port/)
      end

      it 'accepts valid protocols' do
        options = base_options.merge(gce_ports: ['80/tcp', '443/udp'])

        expect do
          described_class.new(options)
        end.not_to raise_error
      end
    end
  end
end
