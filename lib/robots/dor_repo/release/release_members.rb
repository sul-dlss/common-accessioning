# frozen_string_literal: true

# Robot class to run under multiplexing infrastructure
module Robots
  module DorRepo
    module Release
      class ReleaseMembers < Robots::DorRepo::Base
        def initialize
          super('releaseWF', 'release-members', check_queued_status: true) # init LyberCore::Robot
        end

        # `perform` is the main entry point for the robot. This is where
        # all of the robot's work is done.
        #
        # @param [String] druid -- the Druid identifier for the object to process
        def perform(druid)
          LyberCore::Log.debug "release-members working on #{druid}"

          # `#find` returns an instance of a model from the cocina-models gem
          obj = Dor::Services::Client.object(druid).find
          return unless obj.collection?

          publish_collection(druid: druid, object: obj)
        end

        private

        def publish_collection(druid:, object:)
          member_service = Dor::Release::MemberService.new(druid: druid)
          add_workflow_to_members(member_service) if add_wf_to_members?(object)
          add_workflow_to_sub_collections(member_service)
        end

        # Here's an example of the kinds of tags we're dealing with:
        #   https://argo.stanford.edu/view/druid:fh138mm2023
        # @return [boolean] returns true if the most recent releaseTags for any target is "collection"
        def add_wf_to_members?(object)
          object.administrative.releaseTags
                .group_by(&:to)
                .each_with_object({}) { |(key, v), out| out[key] = v.max_by(&:date) }
                .values.map(&:what).any? { |x| x == 'collection' }
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
          current_version = object_client.version.current
          workflow_service.create_workflow_by_name(druid, 'releaseWF', version: current_version, lane_id: lane_id(druid))
        end
      end
    end
  end
end
