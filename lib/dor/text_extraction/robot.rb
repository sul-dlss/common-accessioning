# frozen_string_literal: true

module Dor
  module TextExtraction
    # Provides common functionality, such as access to AWS
    class Robot < LyberCore::Robot
      protected

      def aws_provider
        @aws_provider ||= Dor::TextExtraction::AwsProvider.new(region: Settings.aws.region, access_key_id: Settings.aws.access_key_id, secret_access_key: Settings.aws.secret_access_key)
      end
    end
  end
end
