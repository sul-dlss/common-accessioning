# frozen_string_literal: true

module Robots
  module DorRepo
    module SpeechToText
      # Call the speech to text service to generate text
      class SttCreate < LyberCore::Robot
        def initialize
          super('speechToTextWF', 'stt-create')
        end

        # available from LyberCore::Robot: druid, bare_druid, workflow_service, object_client, cocina_object, logger
        def perform_work
          # start the caption creation by sending an SQS message to the caption creation service
          send_sqs_message

          # Leave this step running until the Whisper monitoring job marks it as complete
          LyberCore::ReturnState.new(status: :noop, note: 'Initiated SpeechToText.')
        end

        private

        def aws_provider
          @aws_provider ||= Dor::TextExtraction::AwsProvider.new(region: Settings.aws.region, access_key_id: Settings.aws.access_key_id, secret_access_key: Settings.aws.secret_access_key)
        end

        def send_sqs_message
          # Define the queue URL and message body
          queue_url = Settings.aws.sqs_queue_url
          message_body = {
            druid: druid,
            action: 'create_captions'
          }.to_json

          # Send the message to the SQS queue
          aws_provider.sqs.send_message({
            queue_url: queue_url,
            message_body: message_body
          })

          logger.info("Sent SQS message for druid #{druid} to queue #{queue_url}")
        end
      end
    end
  end
end
