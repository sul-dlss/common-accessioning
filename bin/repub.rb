#!/usr/bin/env ruby
unless(ARGV.first.nil?)
  ENV['ROBOT_ENVIRONMENT'] = ARGV.first
end

require File.expand_path(File.dirname(__FILE__) + '/../config/boot')

IO.readlines('/home/lyberadmin/repub_druids.txt').each do |druid|
  begin
    puts "Republishing #{druid}"
    o = Dor::Item.find(druid)
    o.publish_metadata
  rescue Exception => e
    puts "ERR Problem with #{druid}\n" << e.inspect << "\n" << e.backtrace.join("\n")
  end
end
puts "Done!"
