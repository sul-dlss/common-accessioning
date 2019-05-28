# frozen_string_literal: true

module Robots
  module DorRepo
    module Accession
      # Creates the rightsMetadata datastream
      class RightsMetadata < Robots::DorRepo::Base
        def initialize
          super('dor', 'accessionWF', 'rights-metadata')
        end

        def perform(druid)
          obj = Dor.find(druid)
          builder = DatastreamBuilder.new(object: obj,
                                          datastream: obj.rightsMetadata)

          builder.build do |datastream|
            build_datastream(obj, datastream)
          end
        end

        def build_datastream(obj, datastream)
          datastream.dsLabel = 'Rights Metadata'
          datastream.ng_xml = obj.admin_policy_object.defaultObjectRights.ng_xml.clone
        end
      end
    end
  end
end