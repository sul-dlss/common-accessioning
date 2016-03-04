
module Robots
  module DorRepo
    module Accession

      class ResetWorkspace < Robots::DorRepo::Accession::Base
        def initialize
          super('dor', 'accessionWF', 'reset-workspace')
        end

        def perform(druid)
          druid_obj = Dor::find(druid)
          version = druid_obj.current_version

          workspace_root = Dor::Config.stacks.local_workspace_root
          export_home = Dor::Config.cleanup.local_export_home

          Dor::ResetWorkspaceService.reset_workspace_druid_tree(druid, version, workspace_root)
          Dor::ResetWorkspaceService.reset_export_bag(druid, version, export_home)
        end
      end

    end
  end
end
