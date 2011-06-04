require 'rake'
require 'rake/testtask'
require 'spec/rake/spectask'

# Import external rake tasks
Dir.glob('lib/tasks/*.rake').each { |r| import r }

task :default  => [:rspec_with_rcov, :doc]

require 'spec/rake/verify_rcov'
RCov::VerifyTask.new(:verify_rcov => ['rspec_with_rcov', 'doc']) do |t|
  t.threshold = 79.64
  t.index_html = 'coverage/index.html'
end

desc "Run RSpec with RCov"
Spec::Rake::SpecTask.new('rspec_with_rcov') do |t|
  t.spec_files = FileList['spec/*_spec.rb','spec/**/*_spec.rb']
  t.rcov = true
  t.rcov_opts = %w{--exclude spec\/*,gems\/*,ruby\/* --aggregate coverage.data}  
end

desc "Run integration tests"
Spec::Rake::SpecTask.new('integration') do |t|
  t.spec_files = FileList['integration_tests/*_spec.rb']
end

task :clean do
  puts 'Cleaning old coverage.data'
  FileUtils.rm('coverage.data') if(File.exists? 'coverage.data')
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end
