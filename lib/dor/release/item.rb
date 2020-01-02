# frozen_string_literal: true

require 'retries'
require 'dor-fetcher'

module Dor
  module Release
    class Item
      attr_accessor :druid, :fetcher

      def initialize(params = {})
        # Takes a druid, either as a string or as a Druid object.
        @druid = params[:druid]
        skip_heartbeat = params[:skip_heartbeat] || false
        @fetcher = DorFetcher::Client.new(service_url: Settings.release.fetcher_root, skip_heartbeat: skip_heartbeat)
      end

      def object
        @object ||= Dor.find(@druid)
      end

      def members
        @members || with_retries(max_tries: Settings.release.max_tries, base_sleep_seconds: Settings.release.base_sleep_seconds, max_sleep_seconds: Settings.release.max_sleep_seconds) do |_attempt|
          @members = @fetcher.get_collection(@druid) # cache members in an instance variable
        end
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

      def object_type
        unless @obj_type
          obj_type = object.identityMetadata.objectType
          @obj_type = (obj_type.nil? ? 'unknown' : obj_type.first)
        end
        @obj_type.downcase.strip
      end
    end
  end
end
