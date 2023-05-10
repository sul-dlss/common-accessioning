# frozen_string_literal: true

# Robot class to run under multiplexing infrastructure
module Robots
  module DorRepo
    module Release
      class ReleaseMembers < LyberCore::Robot
        def initialize
          super('releaseWF', 'release-members')
        end

        # `perform` is the main entry point for the robot. This is where
        # all of the robot's work is done.
        #
        # @param [String] druid -- the Druid identifier for the object to process
        def perform_work
          logger.debug "release-members working on #{druid}"

          return unless cocina_object.collection?

          publish_collection
        end

        private

        def publish_collection
          member_service = Dor::Release::MemberService.new(druid:)
          add_workflow_to_members(member_service.items) if add_wf_to_members?
          add_workflow_to_members(member_service.sub_collections)
        end

        # Here's an example of the kinds of tags we're dealing with:
        #   https://argo.stanford.edu/view/druid:fh138mm2023
        # @return [boolean] returns true if the most recent releaseTags for any target is "collection"
        def add_wf_to_members?
          cocina_object.administrative.releaseTags
                       .group_by(&:to)
                       .each_with_object({}) { |(key, v), out| out[key] = v.max_by(&:date) }
                       .values.map(&:what).any? { |x| x == 'collection' }
        end

        # iterate through any item members and add workflows
        def add_workflow_to_members(members)
          members.each do |member|
            create_release_workflow(member.externalIdentifier)
          end
        end

        def add_workflow_to_sub_collections(member_service)
          member_service.sub_collections&.each do |sub_collection|
            create_release_workflow(sub_collection['druid'])
          end
        end

        def create_release_workflow(druid)
          logger.debug "...adding workflow releaseWF for #{druid}"
          object_client = Dor::Services::Client.object(druid)

          # initiate workflow by making workflow service call
          current_version = object_client.version.current
          workflow_service.create_workflow_by_name(druid, 'releaseWF', version: current_version, lane_id:)
        end
      end
    end
  end
end
