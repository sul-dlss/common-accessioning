#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'

module Robots
  module DorRepo
    module EtdSubmit
      class OtherMetadata < Robots::DorRepo::EtdSubmit::Base
        def initialize(opts = {})
          super('dor', 'etdSubmitWF', 'other-metadata', opts)
        end

        def perform(druid)
          # create metadata datastreams for the work item
          etd = Etd.find(druid)

          druid_tools_druid = DruidTools::Druid.new(druid, Dor::Config.sdr.local_workspace_root)
          content_dir = druid_tools_druid.content_dir

          # now transfer the pdfs from lyberapps into the workspace parent content directory
          source_dir = File.join(ETD_WORKSPACE, druid)
          transfer_object(source_dir, content_dir)

          return if etd.nil?

          etd.populate_datastream('contentMetadata')
          etd.populate_datastream('rightsMetadata')
          etd.populate_datastream('identityMetadata')
          etd.populate_datastream('versionMetadata')
        end

        # This method transfers all the directories using rsync.
        # Is similar to the LyberCore::Utils::FilUtilities.transfer_object, but
        # does recursive downloads.
        #
        def transfer_object(source_dir, dest_dir)
          rsync = 'rsync -a -e ssh --recursive --checksum  '
          rsync_cmd = rsync + "'" + source_dir + "/' " + dest_dir + '/'
          execute(rsync_cmd)
          raise "#{File.basename(source_dir)} is not found in #{dest_dir}" unless File.exist?(dest_dir)

          true
        rescue StandardError => e
          LyberCore::Log.fatal "Can't rsync contents from #{source_dir} to #{dest_dir}: #{e}"
          raise
        end

        def ensure_workspace_exists(workspace)
          FileUtils.mkdir_p(workspace) unless File.directory?(workspace)
        rescue StandardError
          LyberCore::Log.fatal("Can't create workspace_base #{workspace}")
          raise
        end

        private

        def execute(command)
          status, stdout, stderr = systemu(command)
          raise stderr if status.exitstatus != 0

          stdout
        rescue StandardError
          msg = "Command failed to execute: [#{command}] caused by <STDERR = #{stderr.split($INPUT_RECORD_SEPARATOR).join('; ')}>"
          msg << " STDOUT = #{stdout.split($INPUT_RECORD_SEPARATOR).join('; ')}" if stdout && !stdout.empty?
          raise msg
        end
      end
    end
  end
end
