# frozen_string_literal: true

server 'common-accessioning-prod-a.stanford.edu', user: 'lyberadmin', roles: %w[app]
server 'common-accessioning-prod-b.stanford.edu', user: 'lyberadmin', roles: %w[app]
server 'common-accessioning-prod-c.stanford.edu', user: 'lyberadmin', roles: %w[app]
server 'common-accessioning-prod-d.stanford.edu', user: 'lyberadmin', roles: %w[app]

Capistrano::OneTimeKey.generate_one_time_key!

set :deploy_environment, 'production'
set :default_env, robot_environment: fetch(:deploy_environment)
# See https://github.com/honeybadger-io/honeybadger-ruby/issues/129 &
# https://github.com/honeybadger-io/honeybadger-ruby/blob/7eea24a47d44aed663e315be970e501b7cf092fc/vendor/capistrano-honeybadger/README.md
set :honeybadger_server, primary(:app)
