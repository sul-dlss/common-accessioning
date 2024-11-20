# frozen_string_literal: true

module Dor
  module TextExtraction
    # Watch an SQS queue for messages by long polling, allowing the consumer
    # of this class to specify the queue name and the processing logic.
    class SqsWatcher
      attr_reader :logger, :queue_url, :role_arn, :visibility_timeout, :max_attempts

      def initialize(queue_url:, role_arn: nil, logger: Logger.new($stdout), visibility_timeout: nil, max_attempts: nil)
        @queue_url = queue_url
        @role_arn = role_arn
        @logger = logger
        @visibility_timeout = visibility_timeout || default_visibility_timeout
        @max_attempts = max_attempts || default_max_attempts
      end

      # @yieldparam [Aws::SQS::Types::Message] an SQS message to be processed
      def poll
        logger.info("Starting indefinite long polling of #{queue_url}")
        poller.poll(visibility_timeout:) do |sqs_msg|
          yield sqs_msg
        rescue StandardError => e
          handle_sqs_message_processing_error(sqs_msg:, error: e)
        end
      end

      private

      def poller
        options = { client: aws_provider.sqs }
        Aws::SQS::QueuePoller.new(queue_url, options).tap do |poller|
          logger.info("created QueuePoller: #{poller.inspect}")
        end
      end

      def handle_sqs_message_processing_error(sqs_msg:, error:)
        context = { sqs_msg:, error: }

        if sqs_msg[:attributes]['ApproximateReceiveCount'].to_i <= max_attempts
          logger.warn("Error processing SQS message, skipping deletion to allow requeue. Context: #{context}")
          Honeybadger.notify('Error processing SQS message, skipping deletion to allow requeue', context:)

          # without this throw, the message would be deleted upon completion of the block, preventing retry
          throw :skip_delete
        else
          logger.error("Max retries exceeded for message, message will be deleted from queue! Context: #{context}")
          Honeybadger.notify('Max retries exceeded for message, message will be deleted from queue!', context:)
        end
      end

      def default_visibility_timeout
        120 # pick a reasonable default time by which the job should complete successfully, or allow the message to be requeued for retry
      end

      def default_max_attempts
        3
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
