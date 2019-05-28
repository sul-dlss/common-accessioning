# frozen_string_literal: true

module Robots
  module DorRepo
    module Dissemination
      class Cleanup < Robots::DorRepo::Base
        def initialize
          super('dor', 'disseminationWF', 'cleanup')
        end

        def perform(druid)
          # decide whether the druid is full or truncated
          if is_full_druid_tree(druid)
            CleanupResetService.cleanup_by_reset_druid druid
          else
            Dor::CleanupService.cleanup_by_druid druid
          end
        end

        # determines if the druid is the regular druid tree or the truncated one
        def is_full_druid_tree(druid)
          workspace_root = Dor::Config.cleanup.local_workspace_root
          full_druid_tree = DruidTools::Druid.new(druid, workspace_root)
          truncate_druid_tree = DruidTools::AccessDruid.new(druid, workspace_root)
          (!Dir.glob(truncate_druid_tree.path).empty? && !Dir.glob(full_druid_tree.path + '*').empty?)
        end
      end
    end
  end
end