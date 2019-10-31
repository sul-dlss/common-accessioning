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
          # This is an async result and it will have a callback.
          Dor::Services::Client.object(druid).shelve
          # rubocop:disable Lint/HandleExceptions
        rescue Dor::Services::Client::UnexpectedResponse
          # nop - this object wasn't an item.
          # rubocop:enable Lint/HandleExceptions
        end
      end
    end
  end
end
