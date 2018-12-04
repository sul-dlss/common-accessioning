# frozen_string_literal: true

require 'dor/shelve'

module Robots
  module DorRepo
    module Accession

      class Shelve < Robots::DorRepo::Accession::Base
        def initialize
          super('dor', 'accessionWF', 'shelve')
        end

        def perform(druid)
          obj = Dor.find(druid)
          Dor::Shelve.push(obj) if obj.is_a? Dor::Item
        end
      end
    end
  end
end
