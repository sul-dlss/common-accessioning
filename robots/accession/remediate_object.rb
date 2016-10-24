# Runs all registered dor-services migrations on the object

module Robots
  module DorRepo
    module Accession

      class RemediateObject < Robots::DorRepo::Accession::Base
        def initialize
          super('dor', 'accessionWF', 'remediate-object')
        end

        def perform(druid)
          obj = Dor.find(druid)
          obj.upgrade!
        end
      end

    end
  end
end
