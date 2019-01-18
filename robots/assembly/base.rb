# frozen_string_literal: true

module Robots
  module DorRepo
    module Assembly
      class Base
        include LyberCore::Robot

        def workflow_service
          Dor::Config.workflow.client
        end

        protected

        def with_item(druid, items_only: Dor::Config.configure.assembly.items_only, &block)
          ai = item(druid)

          if items_only && !ai.item?
            LyberCore::Log.info("Skipping #{@step_name} for #{druid} since it is not an item")
          else
            ai.load_content_metadata
            yield ai
          end
        end

        def item(druid)
          Dor::Assembly::Item.new druid: druid
        end
      end
    end
  end
end
