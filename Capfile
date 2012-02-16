load 'deploy' if respond_to?(:namespace) # cap2 differentiator

set :application, "common-accessioning"

require 'net/ssh/kerberos'
set :ssh_options, { :auth_methods => %w(gssapi-with-mic publickey hostbased password keyboard-interactive) }

$:.unshift(File.expand_path('./lib', ENV['rvm_path'])) # Add RVM's lib directory to the load path.
require "rvm/capistrano"                  # Load RVM's capistrano plugin.
set :rvm_ruby_string, "1.8.7@#{application}"        # Or whatever env you want it to run in.

task :dev do
  role :app, "sul-lyberservices-dev.stanford.edu"
  set :bundle_without,  ["deploy"]
  set :deploy_env, "development"
end

task :testing do
  role :app, "sul-lyberservices-test.stanford.edu"
  set :bundle_without,  ["development", "test", "deploy"]
  set :deploy_env, "test"
end

task :production do
  role :app, "sul-lyberservices-prod.stanford.edu"
  set :bundle_without,  ["development", "test", "deploy"]
  set :deploy_env, "production"
end

set :user, "lyberadmin" 
set :destination, "/home/#{user}"

set :scm, :git
set :repository,  "/afs/ir/dev/dlss/git/lyberteam/common-accessioning.git"
set :local_repository, "ssh://wmene@corn.stanford.edu#{repository}"
set :branch, "master"
set :deploy_via, :remote_cache

set :use_sudo, false
set :deploy_to, "#{destination}/#{application}"

#######################################################################
# Overrides
# The rest of the script deals with overriding default capistrano
# behavior with regards to bundler, rvm, and deployment

# Install the gems specified by the Gemfile into the current rvm gemset
require "bundler/capistrano"
set :bundle_dir,      ""              # Do not deploy into a local directory
set :bundle_flags,    "--quiet"       # Do not use the default --deploy flag

# Make sure the gemset exists before running deploy:setup
def disable_rvm_shell(&block)
  old_shell = self[:default_shell]
  self[:default_shell] = nil
  yield
  self[:default_shell] = old_shell
end

task :create_gemset do
  disable_rvm_shell { run "rvm use #{rvm_ruby_string} --create" }
end

before "deploy:setup", "create_gemset"

# Override deploy:finalize_update so that capistrano doesn't create
# rails specific directories that we don't care about
set :shared_children, %w(log config/environments)

namespace :deploy do
  
   desc <<-DESC 
         This overrides the default :finalize_update since we don't care about \
         rails specific directories
   DESC
   task :finalize_update, :except => { :no_release => true } do
     run "chmod -R g+w #{latest_release}" if fetch(:group_writable, true)
     run "rm -rf #{latest_release}/log #{latest_release}/config/environments"
     
     shared_children.map do |d|
       run "ln -s #{shared_path}/#{d} #{latest_release}/#{d}"
     end
   end
end

# after "deploy:symlink", "dlss:update_crontab"
# namespace :dlss do
#   task :update_crontab do
#       run "cd #{release_path}; whenever --set environment=#{deploy_env} --update-crontab #{application}"
#   end
# end


