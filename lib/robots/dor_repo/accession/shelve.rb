# frozen_string_literal: true

module Robots
  module DorRepo
    module Accession
      # Push file changes for shelve-able files into stacks
      class Shelve < Robots::DorRepo::Base
        def initialize
          super('accessionWF', 'shelve')
        end

        def perform(druid)
          object_client = Dor::Services::Client.object(druid)
          # `#find` returns an instance of a model from the cocina-models gem
          obj = object_client.find

          return skip_steps(druid, 'Not an item/DRO, nothing to do') unless obj.dro?

          # No files, so do nothing
          return skip_steps(druid, 'object has no files') if obj.structural.contains.blank?

          # This is an asynchronous result. It will set the shelve-complete workflow to complete when it is done.
          object_client.shelve(lane_id: lane_id(druid))
        end

        # Objects that aren't items/DROs are not shelved, so set the
        # shelve-complete step as completed
        def skip_steps(druid, note)
          # set the shelve-complete step as completed
          workflow_service.update_status(druid: druid,
                                         workflow: 'accessionWF',
                                         process: 'shelve-complete',
                                         status: 'completed',
                                         elapsed: 1,
                                         note: note)
          LyberCore::Robot::ReturnState.new(status: :skipped, note: note)
        end
      end
    end
  end
end
