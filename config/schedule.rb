# frozen_string_literal: true

set :output, '/opt/app/lyberadmin/common-accessioning/current/log/crondebug.log'

set :environment_variable, 'ROBOT_ENVIRONMENT'
job_type :robot_cron, 'cd :path && :environment_variable=:environment :bundle_command bin/run_robot_cron :task :output'

every :day, at: '9:10pm' do
  robot_cron 'dor:etdSubmitWF:submit-marc'
end

every :day, at: '10:10pm' do
  command "cd #{path}; #{environment_variable}=#{environment} #{bundle_command} lib/robots/dor_repo/etd_submit/build_symphony_marc.rb"
end

every :hour, at: 40 do
  # This polls symphony to see if it has the data from submit-marc
  robot_cron 'dor:etdSubmitWF:check-marc'
end

every :hour, at: 41 do
  robot_cron 'dor:etdSubmitWF:catalog-status'
end
