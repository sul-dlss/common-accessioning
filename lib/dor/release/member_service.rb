# frozen_string_literal: true

module Dor
  module Release
    # Retrieves the members of a collection, both items and sub-collections
    class MemberService
      def initialize(druid:)
        @druid = druid
      end

      def items
        members_of_type('item')
      end

      def sub_collections
        members_of_type('collection')
      end

      private

      attr_reader :druid

      def members_of_type(type)
        members.filter { |member| member.type == type }
      end

      def members
        @members ||= Dor::Services::Client.object(druid).members
      end
    end
  end
end
