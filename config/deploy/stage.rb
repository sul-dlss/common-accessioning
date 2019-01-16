# frozen_string_literal: true

server 'common-accessioning-stage-a.stanford.edu', user: 'lyberadmin', roles: %w{web app db} # only server to get whenever cronjobs deployed to
server 'common-accessioning-stage-b.stanford.edu', user: 'lyberadmin', roles: %w{web app}

Capistrano::OneTimeKey.generate_one_time_key!

set :deploy_environment, 'test'
set :whenever_environment, fetch(:deploy_environment)
set :default_env, { :robot_environment => fetch(:deploy_environment) }
set :whenever_roles, [:db, :app]
