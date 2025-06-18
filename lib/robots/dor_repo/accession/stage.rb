# frozen_string_literal: true

module Robots
  module DorRepo
    module Accession
      # Copies files from staging (if present) to workspace
      class Stage < LyberCore::Robot
        def initialize
          super('accessionWF', 'stage')
        end

        def perform_work # rubocop:disable Metrics/AbcSize
          return LyberCore::ReturnState.new(status: :skipped, note: 'object is not an item') unless cocina_object.dro?
          return LyberCore::ReturnState.new(status: :skipped, note: 'no files in staging') unless staging_pathname.exist?

          # Delete the workspace directory if it exists
          workspace_pathname.rmtree if workspace_pathname.exist?

          # Copy from staging to workspace
          workspace_pathname.mkpath
          FileUtils.cp_r(staging_pathname, workspace_pathname.parent)

          # Audit the workspace directory
          check_expected_file_sizes!
        end

        private

        def staging_pathname
          @staging_pathname ||= DruidTools::Druid.new(druid, Settings.sdr.staging_root).pathname
        end

        def workspace_pathname
          @workspace_pathname ||= DruidTools::Druid.new(druid, Settings.sdr.local_workspace_root).pathname
        end

        def check_expected_file_sizes! # rubocop:disable Metrics/AbcSize
          cocina_object.structural.contains.each do |fileset|
            fileset.structural.contains.each do |file|
              file_pathname = workspace_pathname.join('content', file.filename)
              next unless file_pathname.exist? && file_pathname.size != file.size

              raise "File incorrect size: #{file_pathname} expected #{file.size} but actually #{file_pathname.size}"
            end
          end
        end
      end
    end
  end
end
