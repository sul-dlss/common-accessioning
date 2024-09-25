# frozen_string_literal: true

module Dor
  module TextExtraction
    # The Application's configured interface to AWS.
    class AwsProvider
      delegate :client, to: :resource
      attr_reader :aws_client_args

      def initialize(region:, access_key_id:, secret_access_key:)
        @aws_client_args = {
          region:,
          access_key_id:,
          secret_access_key:
        }
      end

      # @return [::Aws::S3::Bucket]
      def bucket
        resource.bucket(bucket_name)
      end

      # @return [String]
      def bucket_name
        Settings.aws.speech_to_text.base_s3_bucket
      end

      # @return [String]
      def sqs_new_job_queue_url
        Settings.aws.speech_to_text.sqs_new_job_queue_url
      end

      # @return [::Aws::SQS::Client]
      def sqs
        @sqs ||= ::Aws::SQS::Client.new(aws_client_args)
      end

      # @return [::Aws::S3::Resource]
      def resource
        ::Aws::S3::Resource.new(aws_client_args)
      end
    end
  end
end
