# frozen_string_literal: true

require 'retries'
require 'dor-fetcher'

module Dor
  module Release
    # Retrieves the members of a collection, both items and sub-collections
    class MemberService
      def initialize(druid:, skip_heartbeat: false)
        @druid = druid
        @skip_heartbeat = skip_heartbeat
      end

      def item_members
        members['items'] || []
      end

      def sub_collections
        unless @sub_collections
          @sub_collections = []
          @sub_collections += members['sets'] if members['sets']
          @sub_collections += members['collections'] if members['collections']
          @sub_collections.delete_if { |collection| collection['druid'] == druid } # if this is a collection, do not include yourself in the sub-collection list
        end
        @sub_collections
      end

      private

      attr_reader :druid, :skip_heartbeat

      def fetcher
        @fetcher ||= DorFetcher::Client.new(service_url: Settings.release.fetcher_root, skip_heartbeat: skip_heartbeat)
      end

      def members
        @members || with_retries(max_tries: Settings.release.max_tries, base_sleep_seconds: Settings.release.base_sleep_seconds, max_sleep_seconds: Settings.release.max_sleep_seconds) do |_attempt|
          @members = fetcher.get_collection(druid) # cache members in an instance variable
        end
      end
    end
  end
end
