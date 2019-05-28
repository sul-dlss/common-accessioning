# frozen_string_literal: true

module Robots
  module DorRepo
    module Accession
      class EndAccession < Robots::DorRepo::Base
        def initialize
          super('dor', 'accessionWF', 'end-accession')
        end

        def perform(druid)
          druid_obj = Dor.find(druid)

          # Search for the specialized workflow
          next_dissemination_wf = special_dissemination_wf(druid_obj)
          Dor::Config.workflow.client.create_workflow_by_name(druid, next_dissemination_wf) if next_dissemination_wf.present?

          # Call the default disseminationWF in all cases
          Dor::Config.workflow.client.create_workflow_by_name(druid, 'disseminationWF')
        end

        private

        # This returns any optional workflow such as wasDisseminationWF
        def special_dissemination_wf(druid_obj)
          apo = druid_obj.admin_policy_object
          raise "#{druid_obj.id} doesn't have a valid apo" if apo.nil?

          adminMetadata = apo.datastreams['administrativeMetadata'].content
          adminMetadata_xml = Nokogiri::XML(adminMetadata)
          wf = adminMetadata_xml.xpath('//administrativeMetadata/dissemination/workflow/@id').text
          return nil if wf == 'disseminationWF'

          wf
        end
      end
    end
  end
end