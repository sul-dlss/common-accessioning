# frozen_string_literal: true

module Robots
  module DorRepo
    module Accession
      # Kicks off accessioning by making sure the item is not open
      class StartAccession < LyberCore::Robot
        def initialize
          super('accessionWF', 'start-accession')
        end

        def perform_work
          Honeybadger.notify('[WARNING] Accessioning has been started with an object that is still open') if object_client.version.status.open?
        end
      end
    end
  end
end
