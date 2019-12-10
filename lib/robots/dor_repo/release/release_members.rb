# frozen_string_literal: true

# Robot class to run under multiplexing infrastructure
module Robots
  module DorRepo
    module Release
      class ReleaseMembers < Robots::DorRepo::Base
        def initialize
          super('dor', 'releaseWF', 'release-members', check_queued_status: true) # init LyberCore::Robot
        end

        # `perform` is the main entry point for the robot. This is where
        # all of the robot's work is done.
        #
        # @param [String] druid -- the Druid identifier for the object to process
        def perform(druid)
          LyberCore::Log.debug "release-members working on #{druid}"

          item = Dor::Release::Item.new druid: druid

          case item.object_type
          when 'collection', 'set' # this is a collection or set
            publish_collection(item)
          else # this is not a collection of set
            LyberCore::Log.debug "...this is a #{item.object_type}, NOOP"
          end
        end

        private

        def publish_collection(item)
          # check to see if all of the release tags for all targets are what=self, if so, we can skip adding workflow for all the members
          #   if at least one of the targets is *not* what=self, we will do it
          tag_service = Dor::ReleaseTagService.for(item.object)
          release_tags = tag_service.newest_release_tag(tag_service.release_tags) # get the latest release tag for each target
          if release_tags.collect { |_k, v| v['what'] == 'self' }.include?(false) # if there are any *non* what=self release tags in any targets, go ahead and add the workflow to the items
            add_workflow_to_members(item)
          else # all of the latest release tags are what=self or there are no release tags, so skip
            LyberCore::Log.debug "...all release tags are what=self for #{item.object_type}; skipping member workflows"
          end

          add_workflow_to_sub_collections(item)
        end

        def add_workflow_to_members(item)
          LyberCore::Log.debug "...fetching members of #{item.object_type}"
          if item.item_members # if there are any members, iterate through and add item workflows (which includes setting the first step to completed)

            item.item_members.each do |item_member|
              create_release_workflow(item_member['druid'])
            end
          else # no members found
            LyberCore::Log.debug "...no members found in #{item.object_type}"
          end
        end

        def add_workflow_to_sub_collections(item)
          item.sub_collections&.each do |sub_collection|
            create_release_workflow(sub_collection['druid'])
          end
        end

        def create_release_workflow(druid)
          LyberCore::Log.debug "...adding workflow releaseWF for #{druid}"
          object_client = Dor::Services::Client.object(druid)

          # initiate workflow by making workflow service call
          with_retries(max_tries: Settings.release.max_tries, base_sleep_seconds: Settings.release.base_sleep_seconds, max_sleep_seconds: Settings.release.max_sleep_seconds) do |_attempt|
            current_version = object_client.version.current
            Dor::Config.workflow.client.create_workflow_by_name(druid, 'releaseWF', version: current_version)
          end
        end
      end
    end
  end
end
