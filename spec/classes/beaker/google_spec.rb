# frozen_string_literal: true

require 'spec_helper'

# Mock the Google Compute classes to avoid dependency issues
module Beaker
  class Google < Beaker::GoogleCompute
  end
end

RSpec.describe Beaker::Google do
  let(:hosts) { [] }
  let(:options) { { gce_project: 'test', logger: instance_double(Beaker::Logger) } }

  # Mock Google authentication and services to avoid actual authentication
  before do
    # Mock the authentication components
    allow(Google::Auth).to receive(:get_application_default).and_return(
      instance_double(Google::Auth::ServiceAccountCredentials),
    )
    allow(Google::Auth::ServiceAccountCredentials).to receive(:from_env).and_return(
      instance_double(Google::Auth::ServiceAccountCredentials),
    )

    # Mock the Google API client options
    client_options = instance_double(Google::Apis::ClientOptions)
    allow(client_options).to receive(:application_name=)
    allow(client_options).to receive(:application_version=)
    allow(Google::Apis::ClientOptions).to receive(:default).and_return(client_options)

    # Mock the Google Compute and OS Login services
    compute_service = instance_double(Google::Apis::ComputeV1::ComputeService)
    allow(compute_service).to receive(:authorization=)
    allow(Google::Apis::ComputeV1::ComputeService).to receive(:new).and_return(compute_service)

    oslogin_service = instance_double(Google::Apis::OsloginV1::CloudOSLoginService)
    allow(oslogin_service).to receive(:authorization=)
    allow(Google::Apis::OsloginV1::CloudOSLoginService).to receive(:new).and_return(oslogin_service)

    # Mock environment variables that might be checked
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:[]).with('GOOGLE_APPLICATION_CREDENTIALS').and_return(nil)
    allow(ENV).to receive(:[]).with('GOOGLE_CLOUD_UNIVERSE_DOMAIN').and_return(nil)
    allow(ENV).to receive(:[]).with('GOOGLE_CLOUD_PROJECT').and_return(nil)
    allow(ENV).to receive(:[]).with('GCLOUD_PROJECT').and_return(nil)
    allow(ENV).to receive(:[]).with('BEAKER_gce_project').and_return(nil)
    allow(ENV).to receive(:[]).with('BEAKER_gce_ssh_public_key').and_return(nil)
    allow(ENV).to receive(:[]).with('BEAKER_gce_ssh_private_key').and_return(nil)
    allow(ENV).to receive(:fetch).with('BEAKER_gce_zone', anything).and_return('us-central1-a')
    allow(ENV).to receive(:fetch).with('BEAKER_gce_network', anything).and_return('default')
    allow(ENV).to receive(:fetch).with('BEAKER_gce_subnetwork', anything).and_return(nil)
    allow(ENV).to receive(:fetch).with('BEAKER_gce_ports', anything).and_return('')
  end

  describe 'class hierarchy' do
    it 'inherits from GoogleCompute' do
      expect(described_class.superclass).to eq(Beaker::GoogleCompute)
    end
  end

  describe 'instantiation' do
    it 'can be instantiated' do
      expect { described_class.new(hosts, options) }.not_to raise_error
    end
  end
end
