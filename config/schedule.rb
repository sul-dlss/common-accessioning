# frozen_string_literal: true

# Learn more: http://github.com/javan/whenever

set :output, 'log/cron.log'
set :environment_variable, 'ROBOT_ENVIRONMENT'

# weekly cleanup of empty ABBYY folders in case cleanup step itself didn't do it correctly
every :monday, at: '1am', roles: [:ocr_cleanup] do
  rake 'abbyy:cleanup[true]'
end
