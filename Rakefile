# frozen_string_literal: true

require 'rake'
require 'rake/testtask'

# Import external rake tasks
Dir.glob('lib/tasks/*.rake').each { |r| import r }

task default: %i[rubocop spec]

task :clean do
  puts 'Cleaning old coverage.data'
  FileUtils.rm_rf('coverage.data')
end

begin
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new
rescue LoadError
  # should only get here from production
  desc 'Run rubocop'
  task :rubocop do
    abort 'Please install the rubocop gem to run rubocop.'
  end
end

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
  # should only get here from production or dev environments
  puts 'no rspec found;  hopefully this is a production environment'
end

desc 'Get application version'
task :app_version do
  puts File.read(File.expand_path('VERSION', __dir__)).chomp
end

task :environment do
  require_relative 'config/boot'
end
