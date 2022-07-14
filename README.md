# beaker-google

Beaker library to use the Google hypervisor

# How to use this wizardry

This is a gem that allows you to use hosts with [google compute](google_compute_engine.md) hypervisor with [Beaker](https://github.com/puppetlabs/beaker).

See the [documentation](docs/manual.md) for the full manual.

Beaker will automatically load the appropriate hypervisors for any given hosts file, so as long as your project dependencies are satisfied there's nothing else to do. No need to `require` this library in your tests.

## With Beaker 3.x
This gem is already included as [beaker dependency](https://github.com/puppetlabs/beaker/blob/master/beaker.gemspec)
for you, so you don't need to do anything special to use this gem's
functionality with Beaker.

This library is included as a dependency of Beaker 3.x versions, so there's nothing to do.

## With Beaker 4.x

As of Beaker 4.0, all hypervisor and DSL extension libraries have been removed and are no longer dependencies. In order to use a specific hypervisor or DSL extension library in your project, you will need to include them alongside Beaker in your Gemfile or project.gemspec. E.g.

~~~ruby
# Gemfile
gem 'beaker', '~>4.0'
gem 'beaker-google'
# project.gemspec
s.add_runtime_dependency 'beaker', '~>4.0'
s.add_runtime_dependency 'beaker-google'
~~~

In Beaker's next major version, the requirement for `beaker-google` will be
pulled from that repo. When that happens, then the usage pattern will change.
In order to use this then, you'll need to include `beaker-google` as a dependency
right next to beaker itself.

# Contributing

Pull requests are welcome!
