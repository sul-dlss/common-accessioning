set :output, '/home/lyberadmin/common-accessioning/current/log/crondebug.log'

every :day, :at => '2:16am' do
 command "ROBOT_ENVIRONMENT=#{environment} /usr/local/rvm/wrappers/ruby-1.8.7-p358\\@common-accessioning/ruby /home/lyberadmin/common-accessioning/current/robots/accession/embargo_release.rb"
end