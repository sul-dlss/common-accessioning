set :output, '/home/lyberadmin/common-accessioning/current/log/crondebug.log'

every :day, :at => '2:16am' do
  command "(cd /home/lyberadmin/common-accessioning/current; ROBOT_ENVIRONMENT=#{environment} ruby ./robots/accession/embargo_release.rb)"
end