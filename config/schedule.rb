# frozen_string_literal: true

set :output, '/home/lyberadmin/common-accessioning/current/log/crondebug.log'

every :day, :at => '2:16am', :roles => [:db] do
 command "cd /home/lyberadmin/common-accessioning/current/ && BUNDLE_GEMFILE=/home/lyberadmin/common-accessioning/current/Gemfile ROBOT_ENVIRONMENT=#{environment} /usr/local/rvm/wrappers/default/ruby /home/lyberadmin/common-accessioning/current/robots/accession/embargo_release.rb"
end

every 5.minutes, :roles => [:app] do
  # cannot use :output with Hash/String because we don't want append behavior
  set :output, proc { '> log/verify.log 2> log/cron.log' }
  set :environment_variable, 'ROBOT_ENVIRONMENT'
  rake 'robots:verify'
end
