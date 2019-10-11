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
          obj = Dor.find(druid)
          # TODO: Use Dor::Services::Client::ObjectClient#find to determine the type.
          #       Currently we can't until #find can differentiate between DRO and Collection
          #       https://github.com/sul-dlss/dor-services-client/issues/106
          return unless obj.is_a?(Dor::Item)

          client = Dor::Services::Client.object(druid)
          client.shelve
        end
      end
    end
  end
end
