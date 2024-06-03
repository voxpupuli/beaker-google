# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('lib', __dir__)
require 'beaker-google/version'

Gem::Specification.new do |s|
  s.name        = 'beaker-google'
  s.version     = BeakerGoogle::VERSION
  s.authors     = %w[Puppet Voxpupuli]
  s.email       = ['voxpupuli@groups.io']
  s.homepage    = 'https://github.com/voxpupuli/beaker-google'
  s.summary     = 'Beaker DSL Extension Helpers!'
  s.description = 'Google Compute Engine support for the Beaker acceptance testing tool.'
  s.license     = 'Apache2'

  s.files         = `git ls-files`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ['lib']

  s.required_ruby_version = Gem::Requirement.new('>= 2.7')

  # Testing dependencies
  s.add_development_dependency 'fakefs', '~> 2.4'
  s.add_development_dependency 'pry', '~> 0.10'
  s.add_development_dependency 'rake', '~> 13.0'
  s.add_development_dependency 'rspec', '~> 3.0'
  s.add_development_dependency 'rspec-its'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'voxpupuli-rubocop', '~> 2.7.0'

  # Documentation dependencies
  s.add_development_dependency 'thin'
  s.add_development_dependency 'yard'

  # Run time dependencies
  s.add_runtime_dependency 'stringify-hash', '~> 0.0.0'

  s.add_runtime_dependency 'google-apis-compute_v1', '~> 0.1'
  s.add_runtime_dependency 'google-apis-oslogin_v1', '~> 0.1'
  s.add_runtime_dependency 'googleauth', '~> 1.2'
end
