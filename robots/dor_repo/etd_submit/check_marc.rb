# frozen_string_literal: true

require 'models/etd'
require 'timeout'

module Robots
  module DorRepo
    module EtdSubmit
      class CheckMarc < Robots::DorRepo::EtdSubmit::Base
        include ::EtdSubmit::RobotCronBase

        def initialize(opts = {})
          super('dor', 'etdSubmitWF', 'check-marc', opts)
          @prerequisites = ['dor:etdSubmitWF:submit-marc']
        end

        #========= This method check symphony and looks for MARC record based on druid ==========#
        def perform(druid)
          etd = Etd.find(druid)

          #========= In symphony, druids are stored as flexkeys, with the 'druid:' replaced by 'dor' ==========#
          flexkey = druid.gsub('druid:', 'dor')
          symphony_xml = Nokogiri::XML(query_symphony(flexkey))

          #========= To DO:  ==========#
          # Check for MARC record, if there, get catkey and make identityMetadata ds
          #============================#

          current_location = symphony_xml.search('/titles/record[home="INTERNET"]/current').first
          catkey_xml = symphony_xml.search('/titles/record[home="INTERNET"]/catkey').first
          return LyberCore::Robot::ReturnState.WAITING if current_location.nil? || catkey_xml.nil?

          #========= Add the identity datastream to dor with ckey  ==========#
          identity_xml = Nokogiri::XML(etd.generate_identity_metadata_xml)
          catkey = identity_xml.search("//otherId[@name = 'catkey']")

          #=========  If isn't a catkey, add it ==============#
          if catkey.empty?
            other_identifier = Nokogiri::XML::Node.new('otherId', identity_xml)
            other_identifier['name'] = 'catkey'
            other_identifier.content = catkey_xml.content
            identity_xml.root << other_identifier
          elsif (catkey.length == 1) && catkey.first.content.empty?
            catkey.first.content = catkey_xml.content
          end

          ds = ActiveFedora::Datastream.new(etd.inner_object, 'identityMetadata', dsLabel: 'identityMetadata', controlGroup: 'X')
          ds.content = identity_xml.to_xml
          etd.add_datastream(ds)
          etd.save

          true
        end

        def query_symphony(flexkey)
          url = URI.parse(SYMPHONY_URL + flexkey)
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
