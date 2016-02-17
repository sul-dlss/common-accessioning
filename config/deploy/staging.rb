server 'sul-robots1-test.stanford.edu', user: 'lyberadmin', roles: %w{web app db} # only server to get whenever cronjobs deployed to
server 'sul-robots2-test.stanford.edu', user: 'lyberadmin', roles: %w{web app}
server 'sul-robots5-test.stanford.edu', user: 'lyberadmin', roles: %w{web app} # WAS robots

Capistrano::OneTimeKey.generate_one_time_key!

set :deploy_environment, 'test'
set :whenever_environment, fetch(:deploy_environment)
set :default_env, { :robot_environment => fetch(:deploy_environment) }
set :whenever_roles, [:db, :app]
