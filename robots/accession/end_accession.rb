
module Robots
  module DorRepo
    module Accession

      class EndAccession < Robots::DorRepo::Accession::Base
        def initialize
          super('dor', 'accessionWF', 'end-accession')
        end

        def perform(druid)
          druid_obj = Dor.find(druid)

          #Search for the specialized workflow
          next_disseminationWF = get_special_disseminationWF(druid_obj)
          if next_disseminationWF != 'disseminationWF' && next_disseminationWF != ''
            druid_obj.initialize_workflow next_disseminationWF
          end

          #Call the default disseminationWF in all cases
          druid_obj.initialize_workflow 'disseminationWF'
        end

        def get_special_disseminationWF(druid_obj)
          apo = druid_obj.admin_policy_object
          if apo.nil?
            raise "#{druid_obj.id} doesn't have a valid apo"
          end

          adminMetadata = apo.datastreams['administrativeMetadata'].content
          adminMetadata_xml = Nokogiri::XML( adminMetadata)
          next_disseminationWF = adminMetadata_xml.xpath('//administrativeMetadata/dissemination/workflow/@id').text
          next_disseminationWF
        end
      end
    end
  end
end
