# frozen_string_literal: true

require 'rspec/core/rake_task'

begin
  require 'voxpupuli/rubocop/rake'
rescue LoadError
  # the voxpupuli-rubocop gem is optional
end

###########################################################
#
#   Documentation Tasks
#
###########################################################
DOCS_DAEMON = 'yard server --reload --daemon --server thin'
FOREGROUND_SERVER = 'bundle exec yard server --reload --verbose --server thin lib/beaker'

def running?(cmdline)
  ps = `ps -ef`
  found = ps.lines.grep(/#{Regexp.quote(cmdline)}/)
  raise StandardError, "Found multiple YARD Servers. Don't know what to do." if found.length > 1

  yes = !found.empty?
  [yes, found.first]
end

def pid_from(output)
  output.squeeze(' ').strip.split[1]
end

desc 'Start the documentation server in the foreground'
task docs: 'docs:clear' do
  original_dir = Dir.pwd
  Dir.chdir(__dir__)
  sh FOREGROUND_SERVER
  Dir.chdir(original_dir)
end

namespace :docs do
  desc 'Clear the generated documentation cache'
  task :clear do
    original_dir = Dir.pwd
    Dir.chdir(__dir__)
    sh 'rm -rf docs'
    Dir.chdir(original_dir)
  end

  desc 'Generate static documentation'
  task gen: 'docs:clear' do
    original_dir = Dir.pwd
    Dir.chdir(__dir__)
    output = `bundle exec yard doc`
    puts output
    raise 'Errors/Warnings during yard documentation generation' if /\[warn\]|\[error\]/.match?(output)

    Dir.chdir(original_dir)
  end

  desc 'Run the documentation server in the background, alias `bg`'
  task background: 'docs:clear' do
    yes, output = running?(DOCS_DAEMON)
    if yes
      puts 'Not starting a new YARD Server...'
      puts "Found one running with pid #{pid_from(output)}."
    else
      original_dir = Dir.pwd
      Dir.chdir(__dir__)
      sh "bundle exec #{DOCS_DAEMON}"
      Dir.chdir(original_dir)
    end
  end

  desc 'Alias for `background`'
  task(:bg) { Rake::Task['docs:background'].invoke }

  desc 'Check the status of the documentation server'
  task :status do
    yes, output = running?(DOCS_DAEMON)
    if yes
      pid = pid_from(output)
      puts "Found a YARD Server running with pid #{pid}"
    else
      puts 'Could not find a running YARD Server.'
    end
  end

  desc 'Stop a running YARD Server'
  task :stop do
    yes, output = running?(DOCS_DAEMON)
    if yes
      pid = pid_from(output)
      puts "Found a YARD Server running with pid #{pid}"
      `kill #{pid}`
      puts 'Stopping...'
      yes, = running?(DOCS_DAEMON)
      if yes
        `kill -9 #{pid}`
        yes, = running?(DOCS_DAEMON)
        if yes
          puts 'Could not Stop Server!'
        else
          puts 'Server stopped.'
        end
      else
        puts 'Server stopped.'
      end
    else
      puts 'Could not find a running YARD Server'
    end
  end
end

begin
  require 'rubygems'
  require 'github_changelog_generator/task'
rescue LoadError
  # the github_changelog_generator gem is optional
else
  GitHubChangelogGenerator::RakeTask.new :changelog do |config|
    config.exclude_labels = %w[duplicate question invalid wontfix wont-fix skip-changelog]
    config.user = 'voxpupuli'
    config.project = 'beaker-google'
    gem_version = Gem::Specification.load("#{config.project}.gemspec").version
    config.future_release = gem_version
  end
end
