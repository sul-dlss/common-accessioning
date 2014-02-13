# config valid only for Capistrano 3.1
lock '3.1.0'

set :application, 'common-accessioning'
set :repo_url, 'https://github.com/sul-dlss/common-accessioning.git'

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }

# Default deploy_to directory is /var/www/my_app
set :deploy_to, "/home/lyberadmin/#{fetch(:application)}"

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
set :log_level, :info

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# set :linked_files, %w{config/database.yml}

# Default value for linked_dirs is []
# set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

set :stages, %W(dev staging production)

set :linked_dirs, %w(log config/environments config/certs)

set :accession_robots, %w(content-metadata descriptive-metadata rights-metadata remediate-object publish shelve technical-metadata provenance-metadata end-accession sdr-ingest-transfer)
set :accession_wf, 'accessionWF'

def robots
  rbts = fetch(:accession_robots).map {|robot| "#{fetch(:accession_wf)}:#{robot}"}
  rbts << 'disseminationWF:cleanup'
end

def released?
  capture("ls -x #{releases_path}").split.length > 0
end


namespace :deploy do

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      # Your restart mechanism here, for example:
      # execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  after :publishing, :restart

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end


  task :stop_robots do
    on roles(:all) do
      next unless released?
      within release_path do
        with path: "#{release_path}/bin:$PATH", robot_environment: fetch(:deploy_environment) do
          execute :run_robot, 'stop', robots
        end
      end
    end
  end

  after :started, :stop_robots

end

