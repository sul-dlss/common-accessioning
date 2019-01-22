#!/usr/bin/env ruby
# frozen_string_literal: true

require 'etd'

module Robots
  module DorRepo
    module EtdSubmit
      class CatalogStatus < Robots::DorRepo::EtdSubmit::Base
        include ::EtdSubmit::RobotCronBase

        def initialize(opts = {})
          super('dor', 'etdSubmitWF', 'catalog-status', opts)
          @prerequisites = ['dor:etdSubmitWF:check-marc']
        end

        #========= This method check symphony and looks for MARC record based on druid ==========#
        def perform(druid)
          #========= To DO:  ======================================================================#
          # 1. Examine <current> for the item defined for <home> = "INTERNET".
          # 2. Update  the symphony-status element in the DOR properties DS ,
          # with any changes in this value.
          # 3. When the <current> value changes to "INTERNET"
          # (i.e <current> = <home> ), mark this step as completed.
          #========================================================================================#

          #========= In symphony, druids are stored as flexkeys, with the 'druid:' replaced by 'dor' ==========#
          flexkey = druid.gsub('druid:', 'dor')
          symphony_xml = Nokogiri::XML(query_symphony(flexkey))

          current_location = symphony_xml.search('/titles/record[home="INTERNET"]/current').first
          home_location = symphony_xml.search('/titles/record[home="INTERNET"]/home').first

          #========= if these nodes are empty, the workflow is not advanced ==========#
          return LyberCore::Robot::ReturnState.WAITING if current_location.nil? || home_location.nil?

          #========= check the symphonystatus and update it with any changes ==========#

          etd_accession_wf = Nokogiri::XML(Dor::WorkflowService.get_workflow_xml('dor', druid, 'etdSubmitWF'))
          status = etd_accession_wf.search('//process[@name = "catalog-status"]').first

          #========= if current_location = home_location, return true to advance workflow ==========#
          return true if current_location.content == home_location.content

          #========= if status != current_location, update the ds ==========#
          return if status['status'] == current_location.content

          @status = current_location.content
          nil
        end

        def query_symphony(flexkey)
          url = URI.parse(Dor::Config.etd.symphony_url + flexkey)
          conn = Faraday.new(url: url)
          res = conn.get do |req|
            req.options.timeout = 20
            req.options.open_timeout = 20
          end
          res.body
        end
      end
    end
  end
end
