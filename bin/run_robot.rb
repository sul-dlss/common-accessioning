# Will run one robot as specified 
# Should be run from the root of the robot project
# Assumes there's a ROBOT_ROOT/.rvmrc file that will load the correct ruby version and gemset, if necessary
# robot_root$ ruby ./bin/run_robot accessionWF publish
#
# From cron
# * * * * bash --login -c 'cd /path/to/robot_root && ruby./bin/run_robot.rb accessionWF publish' > /home/deploy/crondebug.log 2>&1
# TODO keep old option functionality working, ie. --druid druid:12345 --env development

require File.expand_path(File.dirname(__FILE__) + '/../config/boot')

workflow = ARGV.shift
robot_name = ARGV.shift
module_name = workflow.split('WF').first.capitalize

puts "Trying to load #{module_name}::#{robot_name.capitalize}"
robot_klass = Module.const_get(module_name).const_get(robot_name.capitalize)

robot = robot_klass.new
robot.start
