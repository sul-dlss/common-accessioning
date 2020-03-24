#!/usr/bin/env ruby
# frozen_string_literal: true

#
# Reads the day's marc files from the local temporary directory and builds one file
# in the MARC_OUTPUT_DIRECTORY
#
require File.expand_path(File.dirname(__FILE__) + '/../../../../config/boot')
require 'pony'

ETD_ALERTS_LIST = 'etd-alerts@lists.stanford.edu'
LyberCore::Log.set_logfile(File.join(ROBOT_ROOT, 'log', 'build_symphony_marc.log'))

filename = File.join(MARC_OUTPUT_DIRECTORY, Time.now.strftime('%Y%m%d-%H%M%S%u'))

marc_files = Dir[File.join(Settings.marc_workspace, Time.now.strftime('%Y%m%d'), '*.marc')]
if marc_files.empty?
  LyberCore::Log.info('No marc files from today to process')
  exit
end

current = ''
begin
  File.open(filename, 'w') do |marc_file|
    LyberCore::Log.info("Outputting raw marc file --> #{filename}")
    marc_files.each do |fname|
      current = fname
      File.open(fname) { |one_marc| marc_file << one_marc.read }
    end
  end
rescue StandardError => e
  msg = "Problem trying to create Symphony MARC file- #{filename}:\nWhile working on: #{current}\n" << e.inspect << "\n" << e.backtrace.join("\n")
  LyberCore::Log.fatal(msg)
  LyberCore::Log.fatal('Sending alert')
  Pony.mail(to: ETD_ALERTS_LIST.to_s,
            from: ETD_ALERTS_LIST.to_s,
            subject: "[#{ENV['ROBOT_ENVIRONMENT']}] Failed to build MARC for Symphony",
            body: msg,
            via: :smtp,
            via_options: {
              address: 'smtp.stanford.edu',
              port: '25',
              enable_starttls_auto: true,
              authentication: :plain, # :plain, :login, :cram_md5, no auth by default
              domain: 'localhost.localdomain' # the HELO domain provided by the client to the server
            })
end

# TODO: maybe cleanup old tmp marc directories?
