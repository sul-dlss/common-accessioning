# frozen_string_literal: true

server 'common-accessioning-stage-a.stanford.edu', user: 'lyberadmin', roles: %w{app cron} # only server to get whenever cronjobs deployed to
server 'common-accessioning-stage-b.stanford.edu', user: 'lyberadmin', roles: %w{app}

Capistrano::OneTimeKey.generate_one_time_key!

# This gets set as the ROBOT_ENVIRONMENT veriable in crontab (via whenever)
set :deploy_environment, 'production'
set :whenever_environment, fetch(:deploy_environment)
set :default_env, { :robot_environment => fetch(:deploy_environment) }
set :whenever_roles, [:cron]
set :honeybadger_server, primary(:cron)
