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

          cocina_model = Dor::Services::Client.object(@druid).find

          return unless cocina_model.is_a?(Cocina::Models::Collection)

          publish_collection(druid)
        end

        private

        def publish_collection(druid)
          member_service = Dor::Release::MemberService.new(druid: druid)

          # check to see if all of the release tags for all targets are what=self, if so, we can skip adding workflow for all the members
          #   if at least one of the targets is *not* what=self, we will do it
          tag_service = Dor::ReleaseTagService.for(Dor.find(druid))
          release_tags = tag_service.newest_release_tag(tag_service.release_tags) # get the latest release tag for each target
          # if there are any *non* what=self release tags in any targets, go ahead and add the workflow to the items
          add_workflow_to_members(member_service) if release_tags.collect { |_k, v| v['what'] == 'self' }.include?(false)

          add_workflow_to_sub_collections(member_service)
        end

        def add_workflow_to_members(member_service)
          return unless member_service.item_members # if there are any members, iterate through and add item workflows (which includes setting the first step to completed)

          member_service.item_members.each do |item_member|
            create_release_workflow(item_member['druid'])
          end
        end

        def add_workflow_to_sub_collections(member_service)
          member_service.sub_collections&.each do |sub_collection|
            create_release_workflow(sub_collection['druid'])
          end
        end

        def create_release_workflow(druid)
          LyberCore::Log.debug "...adding workflow releaseWF for #{druid}"
          object_client = Dor::Services::Client.object(druid)

          # initiate workflow by making workflow service call
          with_retries(max_tries: Settings.release.max_tries, base_sleep_seconds: Settings.release.base_sleep_seconds, max_sleep_seconds: Settings.release.max_sleep_seconds) do |_attempt|
            current_version = object_client.version.current
            Dor::Config.workflow.client.create_workflow_by_name(druid, 'releaseWF', version: current_version, lane_id: lane_id(druid))
          end
        end
      end
    end
  end
end
