# frozen_string_literal: true

require 'rake'
require 'rake/testtask'
require 'resque/pool/tasks'

# Import external rake tasks
Dir.glob('lib/tasks/*.rake').each { |r| import r }

task default: %i[rubocop spec]

task :clean do
  puts 'Cleaning old coverage.data'
  FileUtils.rm('coverage.data') if (File.exists? 'coverage.data')
end

begin
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new
rescue LoadError
  desc 'Run rubocop'
  task :rubocop do
    abort 'Please install the rubocop gem to run rubocop.'
  end
end

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

desc 'Get application version'
task :app_version do
  puts File.read(File.expand_path('../VERSION', __FILE__)).chomp
end

# Set up resque-pool
task 'resque:pool:setup' do
  Resque::Pool.after_prefork do |_job|
    Resque.redis.client.reconnect
  end
end

task 'resque:setup' => :environment

task :environment do
  require_relative 'config/boot'
end
