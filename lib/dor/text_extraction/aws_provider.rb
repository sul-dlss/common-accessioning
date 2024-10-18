# frozen_string_literal: true

module Dor
  module TextExtraction
    # The Application's configured interface to AWS.
    class AwsProvider
      delegate :client, to: :resource
      attr_reader :aws_client_args

      def initialize(region:, access_key_id:, secret_access_key:, role_arn: nil)
        @aws_client_args = {
          region:,
          access_key_id:,
          secret_access_key:
        }

        # role_arn handling deals with e.g.
        # 'Aws::SQS::Errors::AccessDenied: User: arn:aws:iam::1234567890123:user/uname is not authorized
        # to perform: sqs:receivemessage on resource: arn:aws:sqs:us-west-2:1234567890123:sul-speech-to-text-done
        # because no resource-based policy allows the sqs:receivemessage action' when polling for SQS messages
        return unless role_arn.present?

        # https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/SQS/Client.html
        @aws_client_args[:credentials] = assume_role_credentials(region:, access_key_id:, secret_access_key:, role_arn:)
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
      def sqs_todo_queue_url
        Settings.aws.speech_to_text.sqs_todo_queue_url
      end

      # @return [String]
      def sqs_done_queue_url
        Settings.aws.speech_to_text.sqs_done_queue_url
      end

      # @return [::Aws::SQS::Client]
      def sqs
        @sqs ||= ::Aws::SQS::Client.new(aws_client_args)
      end

      # @return [::Aws::S3::Resource]
      def resource
        ::Aws::S3::Resource.new(aws_client_args)
      end

      private

      def assume_role_credentials(region:, access_key_id:, secret_access_key:, role_arn:)
        # https://docs.aws.amazon.com/sdk-for-ruby/v3/developer-guide/setup-config.html#aws-ruby-sdk-credentials-access-token
        Aws::AssumeRoleCredentials.new(
          client: Aws::STS::Client.new(region:, access_key_id:, secret_access_key:),
          role_arn:,
          role_session_name: 'common-accessioning-session'
        )
      end
    end
  end
end
