# Ensures the existence of a given datastream within
# a digital object, and loads it from the appropriate
# source if necessary.

module Robots
  module DorRepo
    module Accession

      class AbstractMetadata
        include LyberCore::Robot

        def self.params
          { :process_name => nil, :datastream => nil }
        end

        def initialize
          super('dor', 'accessionWF', self.class.params[:process_name])
        end

        def perform(druid)
          obj = Dor::Item.find(druid)
          obj.build_datastream(self.class.params[:datastream], self.class.params[:force] ? true : false, self.class.params[:require] ? true : false)
        end
      end

    end
  end
end
