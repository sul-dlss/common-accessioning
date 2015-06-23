require 'rake'
require 'rake/testtask'
require 'robot-controller/tasks'

# Import external rake tasks
Dir.glob('lib/tasks/*.rake').each { |r| import r }

task :default  => [:spec, :doc]

# require 'spec/rake/verify_rcov'
# RCov::VerifyTask.new(:verify_rcov => ['rspec_with_rcov', 'doc']) do |t|
#   t.threshold = 79.64
#   t.index_html = 'coverage/index.html'
# end

# desc "Run integration tests"
# Spec::Rake::SpecTask.new('integration') do |t|
#   t.spec_files = FileList['integration_tests/*_spec.rb']
# end

task :clean do
  puts 'Cleaning old coverage.data'
  FileUtils.rm('coverage.data') if(File.exists? 'coverage.data')
end

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)


desc 'Get application version'
task :app_version do
  puts File.read(File.expand_path('../VERSION',__FILE__)).chomp
end

task :environment do
  require_relative 'config/boot'
end