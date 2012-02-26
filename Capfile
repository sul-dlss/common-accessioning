# Initial setup run from laptop
# 1) Setup directory structure on remote VM
#   $ cap dev deploy:setup
# 2) Manually copy environment specific config file to $application/shared/config/environments.  
#      Only necessary for initial install
# 3) Manually copy certs to $application/shared/config/certs
#      Only necessary for initial install
# 4) Copy project from source control to remote
#   $ cap dev deploy:update
# 5) Start robots on remote host
#   $ cap dev deploy:start
#
# Future releases will stop the robots, update the code, then start the robots 
#   $ cap dev deploy
# If you only want to stop the robots, update the code, and NOT start the robots
#   $ cap dev deploy:update
#   You can then manually start the robots on your own
#      $ cap dev deploy:start
load 'deploy' if respond_to?(:namespace) # cap2 differentiator
require 'dlss/capistrano/robots'

set :application, "common-accessioning"

task :dev do
  role :app, "sul-lyberservices-dev.stanford.edu"
  set :bundle_without,  []                        # deploy all the gem groups on the dev VM
  set :deploy_env, "development"
end

task :testing do
  role :app, "sul-lyberservices-test.stanford.edu"
  set :deploy_env, "test"
end

task :production do
  role :app, "sul-lyberservices-prod.stanford.edu"
  set :deploy_env, "production"
end

set :user, "lyberadmin" 
set :repository,  "/afs/ir/dev/dlss/git/lyberteam/common-accessioning.git"
set :local_repository, "ssh://wmene@corn.stanford.edu#{repository}"
set :deploy_to, "/home/#{user}/#{application}"

set :shared_config_certs_dir, true

# These are robots that run as background daemons.  They are automatically restarted at deploy time
set :robots, %w(content-metadata descriptive-metadata rights-metadata publish shelve technical-metadata provenance-metadata cleanup)
set :workflow, 'accessionWF'

# common-accession specific tasks to start/stop the republisher
after "dlss:stop_robots", "dlss:stop_republisher"
after "dlss:start_robots", "dlss:start_republisher"
namespace :dlss do
  task :start_republisher do
    run "cd #{current_path}; ROBOT_ENVIRONMENT=#{deploy_env} ./bin/run_republisher_daemon start"
  end
  
  task :stop_republisher do
    run "cd #{current_path}; ROBOT_ENVIRONMENT=#{deploy_env} ./bin/run_republisher_daemon stop" if released
  end
end