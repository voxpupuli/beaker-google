# frozen_string_literal: true

require 'spec_helper'

# Uses the real ComputeService, so the request is built by the installed
# google-apis-compute_v1, including whatever X-Goog-Api-Version it sets.
RSpec.describe Beaker::GoogleComputeHelper do
  subject(:helper) { described_class.new(options) }

  let(:options) do
    {
      gce_project: 'test-project',
      gce_zone: 'us-central1-a',
      gce_ports: [],
      logger: instance_double(Beaker::Logger, debug: nil, info: nil, warn: nil, error: nil),
    }
  end

  before do
    allow(Google::Auth::ServiceAccountCredentials).to receive(:from_env).and_return(nil)
    allow(Google::Auth).to receive(:get_application_default).and_return(nil)
  end

  describe 'Compute API version' do
    # The request as it is sent: prepare! runs just before execution.
    let(:prepared_command) do
      command = nil
      allow(helper.instance_variable_get(:@compute)).to receive(:execute_or_queue_command) { |cmd| command = cmd }
      helper.get_machine_type
      command.tap(&:prepare!)
    end

    it 'sends the API version the helper targets, not the client library default' do
      expect(prepared_command.header['X-Goog-Api-Version']).to eq(described_class::API_VERSION)
    end
  end
end
