
module Robots
  module DorRepo
    module Accession

      class ArchivingWorkspace
        include LyberCore::Robot

        def initialize
          super('dor', 'accessionWF', 'archiving-workspace')
        end

        def perform(druid)
          workspace_root = Config.stacks.local_workspace_root
          Dor::ArchivingWorkspaceService.archive_workspace_druid_tree(druid, workspace_root)
        end
      end

    end
  end
end
