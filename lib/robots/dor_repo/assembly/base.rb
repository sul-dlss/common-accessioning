# frozen_string_literal: true

module Robots
  module DorRepo
    module Assembly
      class Base < LyberCore::Robot
        private

        def check_assembly_item
          return true if assembly_item.item?

          logger.info("Skipping #{@step_name} for #{druid} since it is not an item")
          false
        end

        def assembly_item
          @assembly_item ||= Dor::Assembly::Item.new(druid:)
        end
      end
    end
  end
end
