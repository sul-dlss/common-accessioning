# frozen_string_literal: true

module Robots
  module DorRepo
    module Accession
      class ProvenanceMetadata < Robots::DorRepo::Base
        def initialize
          super('accessionWF', 'provenance-metadata')
        end

        def perform(_druid)
          LyberCore::Robot::ReturnState.new(status: :skipped, note: 'This robot no longer does anything')
        end
      end
    end
  end
end
