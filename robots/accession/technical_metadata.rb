# Initialize technicalMetadata

module Robots
  module DorRepo
    module Accession

      class TechnicalMetadata < AbstractMetadata
        def self.params
          { :process_name => 'technical-metadata', :datastream => 'technicalMetadata', :force => true }
        end
      end

      def perform(druid)
        super(druid)
      rescue Dor::Exception => e
        LyberCore::Log.warn "technical-metadata: #{druid}: Ignoring #{e}"
      end
    end
  end
end
