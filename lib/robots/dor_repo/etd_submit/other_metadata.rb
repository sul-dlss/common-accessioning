#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'

module Robots
  module DorRepo
    module EtdSubmit
      class OtherMetadata < Robots::DorRepo::Base
        def initialize(opts = {})
          super('etdSubmitWF', 'other-metadata', opts)
        end

        # create metadata datastreams for the work item
        def perform(druid)
          etd = Etd.find(druid)

          druid_tools_druid = DruidTools::Druid.new(druid, Settings.sdr.local_workspace_root)
          content_dir = druid_tools_druid.content_dir

          # now transfer the pdfs from lyberapps into the workspace parent content directory
          source_dir = File.join(ETD_WORKSPACE, druid)
          transfer_object(source_dir, content_dir)

          return if etd.nil?

          populate_datastream(etd, 'contentMetadata')
          populate_datastream(etd, 'rightsMetadata')
          populate_datastream(etd, 'identityMetadata')
          populate_datastream(etd, 'versionMetadata')
        end

        # create a datastream in the repository for the given etd object
        def populate_datastream(etd, ds_name)
          metadata = case ds_name
                     when 'identityMetadata' then Dor::Etd::IdentityMetadataGenerator.generate(etd)
                     when 'contentMetadata' then Dor::Etd::ContentMetadataGenerator.generate(etd)
                     when 'rightsMetadata' then Dor::Etd::RightsMetadataGenerator.generate(etd)
                     when 'versionMetadata' then Dor::Etd::VersionMetadataGenerator.generate(etd.pid)
                     end
          return if metadata.nil?

          populate_datastream_in_repository(etd, ds_name, metadata)
        end

        # create a datastream for the given etd object with the given datastream name, label, and metadata blob
        def populate_datastream_in_repository(etd, ds_name, metadata)
          label = case ds_name
                  when 'identityMetadata' then 'Identity Metadata'
                  when 'contentMetadata' then 'Content Metadata'
                  when 'rightsMetadata' then 'Rights Metadata'
                  when 'versionMetadata' then 'Version Metadata'
                  else ''
                  end
          attrs = { mimeType: 'application/xml', dsLabel: label, content: metadata }
          datastream = ActiveFedora::Datastream.new(etd.inner_object, ds_name, attrs)
          datastream.controlGroup = 'M'
          datastream.save
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
          raise "Can't rsync contents from #{source_dir} to #{dest_dir}: #{e.message}"
        end

        def ensure_workspace_exists(workspace)
          FileUtils.mkdir_p(workspace) unless File.directory?(workspace)
        rescue StandardError => e
          LyberCore::Log.fatal("Can't create workspace_base #{workspace}: #{e}")
          raise "Can't create workspace_base #{workspace} #{e.message}"
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
