# frozen_string_literal: true

source ENV.fetch('GEM_SOURCE', 'https://rubygems.org')

gemspec

def location_for(place, fake_version = nil)
  if place =~ /^git:([^#]*)#(.*)/
    [fake_version, { git: Regexp.last_match(1), branch: Regexp.last_match(2), require: false }].compact
  elsif place =~ %r{^file://(.*)}
    ['>= 0', { path: File.expand_path(Regexp.last_match(1)), require: false }]
  else
    [place, { require: false }]
  end
end

# We don't put beaker in as a test dependency because we
# don't want to create a transitive dependency
group :acceptance_testing do
  gem 'beaker', *location_for(ENV.fetch('BEAKER_VERSION', '~> 4.0'))
end

group :release do
  gem 'github_changelog_generator', require: false
end
