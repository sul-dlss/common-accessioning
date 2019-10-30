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
          background_result_url = Dor::Services::Client.object(druid).shelve
          result = Dor::Services::Client::AsyncResult.new(url: background_result_url)

          raise "Job errors from #{background_result_url}: #{result.errors.inspect}" unless result.wait_until_complete
          # rubocop:disable Lint/HandleExceptions
        rescue Dor::Services::Client::UnexpectedResponse
          # nop - this object wasn't an item.
          # rubocop:enable Lint/HandleExceptions
        end
      end
    end
  end
end
