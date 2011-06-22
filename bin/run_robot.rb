# Will run one robot as specified 
# Should be run from the root of the robot project
# Assumes there's a ROBOT_ROOT/.rvmrc file that will load the correct ruby version and gemset, if necessary
# robot_root$ ruby ./bin/run_robot accessionWF publish
# 
# With Options
# Options must be placed BEFORE workflow and robot name
# robot_root$ ruby ./bin/run_robot --druid druid:12345 accessionWF publish
#
# From cron
# * * * * bash --login -c 'cd /path/to/robot_root && ruby./bin/run_robot.rb accessionWF publish' > /home/deploy/crondebug.log 2>&1

require File.expand_path(File.dirname(__FILE__) + '/../config/boot')

robot_name = ARGV.pop.split(/-/).collect { |w| w.capitalize }.join('')
workflow = ARGV.pop
module_name = workflow.split('WF').first.capitalize

puts "Trying to load #{module_name}::#{robot_name.capitalize}"
robot_klass = Module.const_get(module_name).const_get(robot_name.capitalize)

robot = robot_klass.new
robot.start
