# frozen_string_literal: true

module Robots
  module DorRepo
    module Assembly
      class Base < Robots::DorRepo::Base
        protected

        def with_item(druid)
          assembly_item = item(druid)
          if assembly_item.item?
            yield assembly_item
          else
            LyberCore::Log.info("Skipping #{@step_name} for #{druid} since it is not an item")
          end
        end

        def item(druid)
          Dor::Assembly::Item.new druid: druid
        end
      end
    end
  end
end
