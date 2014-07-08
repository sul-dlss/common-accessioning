
module Robots
  module DorRepo
    module Accession

      class ArchiveWorkspace
        include LyberCore::Robot

        def initialize
          super('dor', 'accessionWF', 'archive-workspace')
        end

        def perform(druid)
          druid_obj = Dor::find(druid)
          version = druid_obj.current_version
          workspace_root = Config.stacks.local_workspace_root
          Dor::ArchiveWorkspaceService.archive_workspace_druid_tree(druid, version, workspace_root)
        end
      end

    end
  end
end
