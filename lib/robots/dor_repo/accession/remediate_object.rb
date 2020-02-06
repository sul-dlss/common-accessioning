# frozen_string_literal: true

# Runs all registered dor-services migrations on the object

module Robots
  module DorRepo
    module Accession
      class RemediateObject < Robots::DorRepo::Base
        def initialize
          super('accessionWF', 'remediate-object')
        end

        def perform(druid)
          # nop
        end
      end
    end
  end
end
