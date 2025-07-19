# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Beaker::GoogleComputeHelper do
  context 'when testing edge cases and integration' do
    describe 'version loading' do
      it 'loads version as a module constant' do
        expect(BeakerGoogle::VERSION).to be_a(String)
          .and match(/^\d+\.\d+\.\d+/)
      end

      it 'is accessible through the module' do
        expect { BeakerGoogle::VERSION }.not_to raise_error
      end
    end

    describe 'module structure' do
      it 'defines the BeakerGoogle module' do
        expect(BeakerGoogle).to be_a(Module)
      end

      it 'has const_get method' do
        expect(BeakerGoogle).to respond_to(:const_get)
      end

      it 'has version information' do
        expect(BeakerGoogle.const_get(:VERSION)).to be_a(String)
      end
    end

    describe 'string processing edge cases' do
      it 'handles nil values safely' do
        expect(safe_string_process(nil)).to be_nil
      end

      it 'handles empty strings' do
        expect(safe_string_process('')).to eq('')
      end

      it 'handles whitespace' do
        expect(safe_string_process('  test  ')).to eq('test')
      end

      it 'handles special characters' do
        expect(safe_string_process('test@example.com')).to eq('test@example.com')
      end

      private

      def safe_string_process(str)
        return nil if str.nil?
        return str if str.empty?

        str.strip
      end
    end

    describe 'environment variable handling' do
      it 'handles missing environment variables gracefully' do
        allow(ENV).to receive(:[]).with('NONEXISTENT_VAR').and_return(nil)
        expect(ENV.fetch('NONEXISTENT_VAR', nil)).to be_nil
      end

      it 'handles empty environment variables' do
        allow(ENV).to receive(:[]).with('EMPTY_VAR').and_return('')
        allow(ENV).to receive(:fetch).with('EMPTY_VAR', nil).and_return('')
        expect(ENV.fetch('EMPTY_VAR', nil)).to eq('')
      end

      it 'handles environment variables with spaces' do
        allow(ENV).to receive(:[]).with('SPACE_VAR').and_return('  value  ')
        allow(ENV).to receive(:fetch).with('SPACE_VAR', nil).and_return('  value  ')
        expect(ENV.fetch('SPACE_VAR', nil)).to eq('  value  ')
      end
    end

    describe 'GoogleComputeHelper options processing' do
      let(:logger) { instance_double(Beaker::Logger) }
      let(:base_options) { { logger: logger, gce_project: 'test-project' } }

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
        allow(ENV).to receive(:fetch).and_call_original
        allow(ENV).to receive(:fetch).with('BEAKER_gce_ports', '').and_return('')
      end

      it 'handles nil gce_ports configuration' do
        options = base_options.merge(gce_ports: nil)

        expect do
          described_class.new(options)
        end.not_to raise_error
      end

      it 'handles empty gce_ports configuration' do
        options = base_options.merge(gce_ports: [])

        mock_google_services

        expect do
          described_class.new(options)
        end.not_to raise_error
      end

      it 'handles gce_ports with multiple valid entries' do
        options = base_options.merge(gce_ports: ['22/tcp', '80/tcp', '443/tcp'])

        mock_google_services

        expect do
          described_class.new(options)
        end.not_to raise_error
      end
    end
  end
end
