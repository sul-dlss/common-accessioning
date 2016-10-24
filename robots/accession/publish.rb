# Clears the way for the standalone publishing robot to publish
# the object's metadata to the Digital Stacks' document cache

module Robots
  module DorRepo
    module Accession

      class Publish < Robots::DorRepo::Accession::Base
        def initialize
          super('dor', 'accessionWF', 'publish')
        end

        def perform(druid)
          obj = Dor.find(druid)
          obj.publish_metadata
        end
      end

    end
  end
end
