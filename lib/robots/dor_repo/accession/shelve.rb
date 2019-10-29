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

          object_client.shelve if obj.is_a?(Cocina::Models::DRO)
        end
      end
    end
  end
end
