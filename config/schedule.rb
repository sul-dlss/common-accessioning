set :output, '/home/lyberadmin/common-accessioning/current/log/crondebug.log'

every :day, :at => '2:16am', :roles => [:app] do
 command "BUNDLE_GEMFILE=/home/lyberadmin/common-accessioning/current/Gemfile ROBOT_ENVIRONMENT=#{environment} /usr/local/rvm/wrappers/default/ruby /home/lyberadmin/common-accessioning/current/robots/accession/embargo_release.rb"
end