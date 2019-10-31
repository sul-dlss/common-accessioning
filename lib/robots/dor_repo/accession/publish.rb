# frozen_string_literal: true

module Robots
  module DorRepo
    module Accession
      # Sends initial metadata to PURL, in robots/release/release_publish we push
      # to PURL again with updates to identityMetadata
      class Publish < Robots::DorRepo::Base
        def initialize
          super('dor', 'accessionWF', 'publish')
        end

        def perform(druid)
          object_client = Dor::Services::Client.object(druid)
          obj = object_client.find

          return if obj.is_a?(Cocina::Models::AdminPolicy)

          background_result_url = object_client.publish
          result = object_client.async_result(url: background_result_url)
          seconds = 2 * 60 * 60 # 2 hours of seconds
          raise "Job errors from #{background_result_url}: #{result.errors.inspect}" unless result.wait_until_complete(timeout_in_seconds: seconds)
        end
      end
    end
  end
end
