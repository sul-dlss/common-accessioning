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

        # create metadata for the work item
        def perform(druid)
          etd = Etd.find(druid)

          object = DruidTools::Druid.new(druid, Settings.sdr.local_workspace_root)
          content_dir = object.content_dir

          # now transfer the pdfs from lyberapps into the workspace parent content directory
          source_dir = File.join(ETD_WORKSPACE, druid)
          transfer_object(source_dir, content_dir)

          return if etd.nil?

          create_metadata(etd, druid)
        end

        private

        # create metadata in the repository for the given etd object
        def create_metadata(etd, druid)
          content_md = Dor::Etd::ContentMetadataGenerator.generate(etd)
          identity_md = Dor::Etd::IdentityMetadataGenerator.generate(etd)
          rights_md = Dor::Etd::RightsMetadataGenerator.generate(etd)
          version_md = Dor::Etd::VersionMetadataGenerator.generate(etd.pid)
          create_legacy_metadata(druid, content_md, identity_md, rights_md, version_md)
        end

        def create_legacy_metadata(druid, content_md, identity_md, rights_md, version_md)
          object_client = Dor::Services::Client.object(druid)

          # legacy_update will create the metadata
          object_client.metadata.legacy_update(
            content: {
              updated: Time.now,
              content: content_md
            },
            identity: {
              updated: Time.now,
              content: identity_md
            },
            rights: {
              updated: Time.now,
              content: rights_md
            },
            version: {
              updated: Time.now,
              content: version_md
            }
          )
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
