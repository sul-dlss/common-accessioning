# frozen_string_literal: true

server 'common-accessioning-prod-a.stanford.edu', user: 'lyberadmin', roles: %w[app cron] # only server to get whenever cronjobs deployed to
server 'common-accessioning-prod-b.stanford.edu', user: 'lyberadmin', roles: %w[app]
server 'common-accessioning-prod-c.stanford.edu', user: 'lyberadmin', roles: %w[app]
server 'common-accessioning-prod-d.stanford.edu', user: 'lyberadmin', roles: %w[app]
server 'common-accessioning-prod-e.stanford.edu', user: 'lyberadmin', roles: %w[app]

Capistrano::OneTimeKey.generate_one_time_key!

set :deploy_environment, 'production'
set :whenever_environment, fetch(:deploy_environment)
set :default_env, robot_environment: fetch(:deploy_environment)
set :whenever_roles, [:cron]

set :honeybadger_server, primary(:cron)
