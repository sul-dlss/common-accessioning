# frozen_string_literal: true

set :application, 'common-accessioning'
set :repo_url, 'https://github.com/sul-dlss/common-accessioning.git'

# Default branch is :main
ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }

# Default deploy_to directory is /var/www/my_app
set :deploy_to, "/opt/app/lyberadmin/#{fetch(:application)}"

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
set :log_level, :info

# Default value for :linked_files is []
set :linked_files, %w[config/honeybadger.yml]

# Default value for linked_dirs is []
# set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

set :stages, %w[dev staging production]

set :linked_dirs, %w[log run config/settings config/certs]

# Prefer capistrano stage over Rails.env (which is typically `production`)
set :honeybadger_env, fetch(:stage)

set :sidekiq_systemd_role, :worker
set :sidekiq_systemd_use_hooks, true

# update shared_configs before restarting app
before 'deploy:publishing', 'shared_configs:update'

# restart abbyy watcher systemd service each deploy
before 'deploy:publishing', 'abbyy_watcher_systemd:restart'

# restart speech-to-text watcher systemd service each deploy
before 'deploy:publishing', 'speech_to_text_watcher_systemd:restart'
