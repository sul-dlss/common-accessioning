# frozen_string_literal: true

$:.unshift File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
$:.unshift File.expand_path(File.join(File.dirname(__FILE__), '..', 'robots'))

require 'rubygems'
require 'bundler/setup'
require 'logger'
require 'honeybadger'

# Load the environment file based on Environment.  Default to development
environment = ENV['ROBOT_ENVIRONMENT'] ||= 'development'
ROBOT_ROOT = File.expand_path(File.dirname(__FILE__) + '/..')
ROBOT_LOG = Logger.new(File.join(ROBOT_ROOT, "log/#{environment}.log"))
ROBOT_LOG.level = Logger::SEV_LABEL.index(ENV['ROBOT_LOG_LEVEL']) || Logger::INFO

# Override Solrizer's logger before it gets a chance to load and pollute
# STDERR.
begin
  require 'solrizer'
  Solrizer.logger = ROBOT_LOG
rescue LoadError, NameError, NoMethodError
end

require 'dor-services'
require 'lyber_core'

# TODO Maybe move auto-require to just run_robot and spec_helper?
Dir["#{ROBOT_ROOT}/lib/**/*.rb"].each { |f| require f }
require 'robots'

env_file = File.expand_path(File.dirname(__FILE__) + "/./environments/#{environment}")
puts "Loading config from #{env_file}"
require env_file

# Configure dor-services-client to use the dor-services URL
Dor::Services::Client.configure(url: Dor::Config.dor_services.url,
                                username: Dor::Config.dor_services.user,
                                password: Dor::Config.dor_services.pass)

# Load Resque configuration and controller
require 'resque'
begin
  if defined? REDIS_TIMEOUT
    _server, _namespace = REDIS_URL.split('/', 2)
    _host, _port, _db = _server.split(':')
    _redis = Redis.new(:host => _host, :port => _port, :thread_safe => true, :db => _db, :timeout => REDIS_TIMEOUT.to_f)
    Resque.redis = Redis::Namespace.new(_namespace, :redis => _redis)
  else
    Resque.redis = REDIS_URL
  end
end
