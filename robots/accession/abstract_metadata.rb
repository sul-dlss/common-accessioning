# frozen_string_literal: true

# Ensures the existence of a given datastream within
# a digital object, and loads it from the appropriate
# source if necessary.

module Robots
  module DorRepo
    module Accession

      class AbstractMetadata < Robots::DorRepo::Accession::Base

        def self.params
          { :process_name => nil, :datastream => nil }
        end

        def initialize
          super('dor', 'accessionWF', self.class.params[:process_name])
        end

        def perform(druid)
          obj = Dor.find(druid)
          builder = Dor::DatastreamBuilder.new(object: obj,
                                               datastream: self.class.params[:datastream],
                                               force: self.class.params[:force] ? true : false,
                                               required: self.class.params[:require] ? true : false)
          builder.build
        end
      end
    end
  end
end
