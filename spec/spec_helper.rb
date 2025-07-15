# frozen_string_literal: true

require 'rspec'
require 'rspec/its'
require 'fakefs/spec_helpers'
require 'simplecov'

# Start SimpleCov if coverage is enabled
SimpleCov.start if ENV['BEAKER_GOOGLE_COVERAGE']

# Require beaker first to establish the base classes
require 'beaker'

# Only require the version module directly
require 'beaker-google/version'

# Require the hypervisor classes
require 'beaker/hypervisor/google_compute_helper'
require 'beaker/hypervisor/google_compute'
require 'beaker/hypervisor/google'

# Load shared mock classes
require_relative 'support/shared_mocks'

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.disable_monkey_patching!
  config.warnings = true

  config.default_formatter = 'doc' if config.files_to_run.one?

  config.profile_examples = 10
  config.order = :random

  Kernel.srand config.seed
end
