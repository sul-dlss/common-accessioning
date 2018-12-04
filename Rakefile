require 'rake'
require 'rake/testtask'
require 'robot-controller/tasks'
require 'rubocop/rake_task'

# Import external rake tasks
Dir.glob('lib/tasks/*.rake').each { |r| import r }

RuboCop::RakeTask.new

task default: %i[rubocop spec]

task :clean do
  puts 'Cleaning old coverage.data'
  FileUtils.rm('coverage.data') if (File.exists? 'coverage.data')
end

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

desc 'Get application version'
task :app_version do
  puts File.read(File.expand_path('../VERSION', __FILE__)).chomp
end

task :environment do
  require_relative 'config/boot'
end
