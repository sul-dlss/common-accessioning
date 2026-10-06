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
          return LyberCore::ReturnState.new(status: :skipped, note: "no files in staging on #{Socket.gethostname}") unless staging_pathname.exist?

          return skip_linked_workspace if linked_to_staging?

          # Delete the workspace directory if it exists
          workspace_pathname.rmtree if workspace_pathname.exist?

          workspace_pathname.mkpath
          # A workspace symlink to staging recently created on another host may not have been visible
          # (e.g., due to NFS caching) until creating the workspace.
          return skip_linked_workspace if linked_to_staging?

          # Copy from staging to workspace
          FileUtils.cp_r(staging_pathname, workspace_pathname.parent)

          # Audit the workspace directory
          check_expected_file_sizes!
        end

        private

        # The workspace may already be a symlink to staging (e.g., created by assemblyWF), so no copy is needed.
        def linked_to_staging?
          File.identical?(staging_pathname, workspace_pathname)
        end

        def skip_linked_workspace
          check_expected_file_sizes!
          LyberCore::ReturnState.new(status: :skipped, note: 'workspace is already linked to staging')
        end

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
