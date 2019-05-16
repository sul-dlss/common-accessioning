# frozen_string_literal: true

module Robots
  module DorRepo
    module Assembly
      class Base < Robots::DorRepo::Base
        protected

        def with_item(druid)
          ai = item(druid)

          if !ai.item?
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
