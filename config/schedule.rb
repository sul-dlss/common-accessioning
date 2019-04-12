# frozen_string_literal: true

set :output, '/opt/app/lyberadmin/common-accessioning/current/log/crondebug.log'

every :day, :at => '2:16am', :roles => [:db] do
 command 'cd /opt/app/lyberadmin/common-accessioning/current/ && ' \
         'BUNDLE_GEMFILE=/opt/app/lyberadmin/common-accessioning/current/Gemfile ' \
         "ROBOT_ENVIRONMENT=#{environment} /usr/local/rvm/wrappers/default/ruby " \
         '/opt/app/lyberadmin/common-accessioning/current/robots/accession/embargo_release.rb'
end
