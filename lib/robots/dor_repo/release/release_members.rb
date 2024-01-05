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
          return unless add_wf_to_members?

          members.each { |member| create_release_workflow(member) }
        end

        private

        def members
          object_client.members.select { |member| published?(member) }
        end

        def published?(member)
          workflow_service.lifecycle(druid: member.externalIdentifier, milestone_name: 'published', version: member.version).present?
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

        def create_release_workflow(member)
          workflow_service.create_workflow_by_name(member.externalIdentifier, 'releaseWF', version: member.version, lane_id:)
        end
      end
    end
  end
end
