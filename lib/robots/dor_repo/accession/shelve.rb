# frozen_string_literal: true

module Robots
  module DorRepo
    module Accession
      # Push file changes for shelve-able files into stacks
      class Shelve < LyberCore::Robot
        def initialize
          super('accessionWF', 'shelve')
        end

        def perform_work
          return LyberCore::ReturnState.new(status: :skipped, note: 'Not an item/DRO, nothing to do') unless cocina_object.dro?

          # Shelving must be done whether an object has files or not, because the shelve call
          # also plays a role in decommissioning an object where the files are removed from stacks.
          # This is an asynchronous result. It will set the shelve workflow to complete when it is done.
          object_client.shelve(lane_id:)
          LyberCore::ReturnState.new(status: :noop, note: 'Initiated shelve API call.')
        end
      end
    end
  end
end
