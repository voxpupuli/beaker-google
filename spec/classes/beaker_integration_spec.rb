# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Beaker do
  context 'when testing Google integration' do
    describe 'basic integration test' do
      let(:logger) { instance_double(Beaker::Logger) }
      let(:test_options) { { logger: logger, gce_project: 'test-project', gce_ports: [] } }

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

      before do
        mock_google_services
      end

      it 'loads the beaker-google version' do
        expect(BeakerGoogle::VERSION).to be_a(String)
      end

      it 'can create GoogleComputeHelper instances' do
        expect do
          Beaker::GoogleComputeHelper.new(test_options)
        end.not_to raise_error
      end

      it 'can create GoogleCompute instances' do
        expect do
          Beaker::GoogleCompute.new([], test_options)
        end.not_to raise_error
      end

      it 'has proper class inheritance' do
        expect(Beaker::GoogleCompute).to be < Beaker::Hypervisor
      end

      it 'loads ComputeV1 API' do
        expect(defined?(Google::Apis::ComputeV1)).to be_truthy
      end

      it 'loads OsloginV1 API' do
        expect(defined?(Google::Apis::OsloginV1)).to be_truthy
      end

      it 'loads Google Auth' do
        expect(defined?(Google::Auth)).to be_truthy
      end
    end
  end
end
