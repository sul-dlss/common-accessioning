# frozen_string_literal: true

module Dor
  module TextExtraction
    # Watch an SQS queue for messages by long polling, allowing the consumer
    # of this class to specify the queue name and the processing logic.
    class SqsWatcher
      attr_reader :logger, :queue_url, :role_arn, :visibility_timeout

      def initialize(queue_url:, role_arn: nil, logger: Logger.new($stdout), visibility_timeout: nil)
        @queue_url = queue_url
        @role_arn = role_arn
        @logger = logger
        @visibility_timeout = visibility_timeout || default_visibility_timeout
      end

      def poll
        logger.info("Starting indefinite long polling of #{queue_url}")
        poller.poll(visibility_timeout:) do |sqs_msg|
          yield sqs_msg
        rescue StandardError => e
          # unexpected error occurred while processing message.
          # log it, and skip delete so it can be re-processed later.
          context = { sqs_msg:, error: e }
          Honeybadger.notify('Error processing SQS message, skipping deletion to allow requeue', context:)
          logger.error("Error processing SQS message, skipping deletion to allow requeue. Context: #{context}")

          # without this throw, the message would be deleted upon completion of the block, preventing retry
          throw :skip_delete # TODO: use msg[:attributes]['ApproximateReceiveCount'] to stop retrying above a certain threshold?
        end
      end

      private

      def poller
        options = { client: aws_provider.sqs }
        Aws::SQS::QueuePoller.new(queue_url, options).tap do |poller|
          logger.info("created QueuePoller: #{poller.inspect}")
        end
      end

      def default_visibility_timeout
        120 # pick a reasonable default time by which the job should complete successfully, or allow the message to be requeued for retry
      end

      def aws_provider
        @aws_provider ||=
          Dor::TextExtraction::AwsProvider.new(region: Settings.aws.region,
                                               access_key_id: Settings.aws.access_key_id,
                                               secret_access_key: Settings.aws.secret_access_key,
                                               role_arn:)
      end
    end
  end
end
