# frozen_string_literal: true

module Robots
  module DorRepo
    module Accession
      # Push file changes for shelve-able files into stacks
      class Shelve < Robots::DorRepo::Base
        def initialize
          super('dor', 'accessionWF', 'shelve')
        end

        def perform(druid)
          object_client = Dor::Services::Client.object(druid)

          # `#find` returns an instance of a model from the cocina-models gem
          if object_client.find.dro?
            # This is an asynchronous result and it will have a callback.
            object_client.shelve
          else
            # Objects that aren't items/DROs are not shelved, so set the
            # shelve-complete step as completed
            workflow_service.update_status(druid: druid,
                                           workflow: 'accessionWF',
                                           process: 'shelve-complete',
                                           status: 'completed',
                                           elapsed: 1,
                                           note: 'Not an item/DRO, nothing to do')
          end
        end
      end
    end
  end
end
