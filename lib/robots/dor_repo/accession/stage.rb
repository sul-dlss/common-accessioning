# frozen_string_literal: true

module Robots
  module DorRepo
    module Accession
      # Moves staged content from the assembly root, or copies it from the staging root, to the workspace
      class Stage < LyberCore::Robot
        def initialize
          super('accessionWF', 'stage')
        end

        def perform_work
          return skipped('object is not an item') unless cocina_object.dro?
          return stage_legacy_symlink if workspace_pathname.symlink?

          staged_content = Dor::StagedContent.find(druid)
          return stage_nothing unless staged_content

          staged_content.assembly? ? move(staged_content.pathname) : copy(staged_content.pathname)
        end

        private

        # Workspaces symlinked by accessioning-initiate before it stopped doing so are left in place.
        def stage_legacy_symlink
          raise "Workspace is a dangling symlink: #{workspace_pathname}" unless workspace_pathname.exist?

          check_expected_file_sizes!
          skipped('workspace is a legacy symlink')
        end

        # Also covers a retry after a move, so the size check still runs.
        def stage_nothing
          check_expected_file_sizes! if workspace_pathname.exist?
          skipped('no staged content')
        end

        def move(source_pathname)
          raise "Staged content in both #{source_pathname} and #{workspace_pathname}" if workspace_pathname.exist?

          workspace_pathname.parent.mkpath
          # Same file system, so atomic; EXDEV is raised rather than falling back to a copy.
          File.rename(source_pathname, workspace_pathname)
          check_expected_file_sizes!
          completed("moved from #{Settings.sdr.assembly_root}")
        end

        # Staging is kept because it is the backed-up copy until preservation.
        def copy(source_pathname)
          workspace_pathname.rmtree if workspace_pathname.exist?
          workspace_pathname.mkpath
          FileUtils.cp_r(source_pathname, workspace_pathname.parent)
          check_expected_file_sizes!
          completed("copied from #{Settings.sdr.staging_root}")
        end

        def skipped(note)
          LyberCore::ReturnState.new(status: :skipped, note:)
        end

        def completed(note)
          LyberCore::ReturnState.new(status: :completed, note:)
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
