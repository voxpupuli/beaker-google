# -*- encoding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require 'beaker-google/version'

Gem::Specification.new do |s|
  s.name        = "beaker-google"
  s.version     = BeakerGoogle::VERSION
  s.authors     = ["Puppet", "Voxpupuli"]
  s.email       = ["voxpupuli@groups.io"]
  s.homepage    = "https://github.com/voxpupuli/beaker-google"
  s.summary     = %q{Beaker DSL Extension Helpers!}
  s.description = %q{Google Compute Engine support for the Beaker acceptance testing tool.}
  s.license     = 'Apache2'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.required_ruby_version = Gem::Requirement.new('>= 2.4')

  # Testing dependencies
  s.add_development_dependency 'rspec', '~> 3.0'
  s.add_development_dependency 'rspec-its'
  s.add_development_dependency 'fakefs', '~> 2.3'
  s.add_development_dependency 'rake', '~> 13.0'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'pry', '~> 0.10'

  # Documentation dependencies
  s.add_development_dependency 'yard'
  s.add_development_dependency 'thin'

  # Run time dependencies
  s.add_runtime_dependency 'stringify-hash', '~> 0.0.0'

  s.add_runtime_dependency 'google-apis-compute_v1', '~> 0.1'
  s.add_runtime_dependency 'google-apis-oslogin_v1', '~> 0.1'
  s.add_runtime_dependency 'googleauth', '~> 1.2'
end
