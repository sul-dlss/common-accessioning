# frozen_string_literal: true

server 'common-accessioning-stage-a.stanford.edu', user: 'lyberadmin', roles: %w[app]
server 'common-accessioning-stage-b.stanford.edu', user: 'lyberadmin', roles: %w[app]

Capistrano::OneTimeKey.generate_one_time_key!

set :deploy_environment, 'production'
set :default_env, robot_environment: fetch(:deploy_environment)
set :honeybadger_server, primary(:cron)
