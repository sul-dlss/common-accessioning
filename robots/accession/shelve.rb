# frozen_string_literal: true

module Robots
  module DorRepo
    module Accession

      class Shelve < Robots::DorRepo::Base
        def initialize
          super('dor', 'accessionWF', 'shelve')
        end

        def perform(druid)
          obj = Dor.find(druid)
          return unless obj.is_a?(Dor::Item)

          Dor::ShelvingService.shelve(obj)
        end
      end
    end
  end
end
