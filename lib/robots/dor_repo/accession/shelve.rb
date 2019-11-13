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
          obj = object_client.find

          # non-items don't shelve anything
          if obj.is_a?(Cocina::Models::DRO)
            # This is an async result and it will have a callback.
            Dor::Services::Client.object(druid).shelve
          else
            # Just set the callback step as complete
            workflow_service.update_status(druid: druid,
                                           workflow: 'accessionWF',
                                           process: 'shelve-complete',
                                           status: 'completed',
                                           elapsed: 1,
                                           note: 'Non-item, nothing to do')
          end
        end
      end
    end
  end
end
