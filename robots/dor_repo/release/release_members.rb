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

            # check to see if all of the release tags for all targets are what=self, if so, we can skip adding workflow for all the members
            #   if at least one of the targets is *not* what=self, we will do it
            tag_service = Dor::ReleaseTagService.for(item.object)
            release_tags = tag_service.newest_release_tag(tag_service.release_tags) # get the latest release tag for each target
            if release_tags.collect { |_k, v| v['what'] == 'self' }.include?(false) # if there are any *non* what=self release tags in any targets, go ahead and add the workflow to the items

              LyberCore::Log.debug "...fetching members of #{item.object_type}"
              if item.item_members # if there are any members, iterate through and add item workflows (which includes setting the first step to completed)

                item.item_members.each do |item_member|
                  Dor::Release::Item.create_release_workflow(item_member['druid'])
                end

              else # no members found

                LyberCore::Log.debug "...no members found in #{item.object_type}"

              end

            else # all of the latest release tags are what=self or there are no release tags, so skip

              LyberCore::Log.debug "...all release tags are what=self for #{item.object_type}; skipping member workflows"

            end

            item.sub_collections&.each do |sub_collection|
              with_retries(max_tries: Dor::Config.release.max_tries, base_sleep_seconds: Dor::Config.release.base_sleep_seconds, max_sleep_seconds: Dor::Config.release.max_sleep_seconds) do |_attempt|
                Dor::Release::Item.create_release_workflow(sub_collection['druid'])
              end
            end

          else # this is not a collection of set

            LyberCore::Log.debug "...this is a #{item.object_type}, NOOP"

          end
        end
      end
    end
  end
end
