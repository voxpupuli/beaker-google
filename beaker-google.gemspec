# frozen-string-literal: true

$LOAD_PATH.unshift File.expand_path('lib', __dir__)
require 'beaker-google/version'

Gem::Specification.new do |s|
  s.name = 'beaker-google'
  s.version = BeakerGoogle::VERSION
  s.authors = ['Rishi Javia, Kevin Imber, Tony Vu']
  s.email = ['rishi.javia@puppet.com, kevin.imber@puppet.com, tony.vu@puppet.com']
  s.homepage = 'https://github.com/puppetlabs/beaker-google'
  s.summary = 'Beaker DSL Extension Helpers!'
  s.description = 'For use for the Beaker acceptance testing tool'
  s.license = 'Apache2'

  s.files = `git ls-files`.split('\n')
  s.executables = `git ls-files -- bin/*`.split('\n').map { |f| File.basename(f) }
  s.require_paths = ['lib']

  # Testing dependencies
  s.add_development_dependency 'rspec', '~> 3.0'
  s.add_development_dependency 'rspec-its'
  # pin fakefs for Ruby < 2.3
  if RUBY_VERSION < "2.3"
    s.add_development_dependency 'fakefs', '~> 1.8'
  else
    s.add_development_dependency 'fakefs', '~> 1.8'
  end
  s.add_development_dependency 'rake', '~> 13.0'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'rubocop-performance'
  s.add_development_dependency 'rubocop-rspec'

  # Documentation dependencies
  s.add_development_dependency 'thin'
  s.add_development_dependency 'yard'

  # Run time dependencies
  s.add_runtime_dependency 'stringify-hash', '~> 0.0.0'

  s.add_runtime_dependency 'google-apis-compute_v1', '~> 0.1'
  s.add_runtime_dependency 'google-apis-oslogin_v1', '~> 0.1'
  s.add_runtime_dependency 'googleauth', '~> 1.2'

  s.metadata['rubygems_mfa_required'] = 'true'
end
