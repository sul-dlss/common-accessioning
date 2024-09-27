# frozen_string_literal: true

module Robots
  module DorRepo
    module SpeechToText
      # Call the speech to text service to generate text
      class SttCreate < Dor::TextExtraction::Robot
        def initialize
          super('speechToTextWF', 'stt-create')
        end

        # available from LyberCore::Robot: druid, bare_druid, workflow_service, object_client, cocina_object, logger
        def perform_work
          # start the caption creation by sending an SQS message to the caption creation service

          send_sqs_message

          # Leave this step running until the Whisper monitoring job marks it as complete
          LyberCore::ReturnState.new(status: :noop, note: 'Initiated SpeechToText.')
        rescue StandardError => e
          Honeybadger.notify('Problem sending SQS Message to AWS for SpeechToText', context: { druid:, error: e })
          raise "Error sending SQS message: #{e.message}"
        end

        private

        def send_sqs_message
          message_body = {
            id: SecureRandom.uuid,
            druid:,
            media:
          }.merge(whisper_options).to_json

          # Send the message to the SQS queue
          aws_provider.sqs.send_message({
                                          queue_url: aws_provider.sqs_todo_queue_url,
                                          message_body:
                                        })

          logger.info("Sent SQS message for druid #{druid} to queue #{aws_provider.sqs_todo_queue_url}")
        end

        def media
          Dor::TextExtraction::SpeechToText.new(cocina_object:, workflow_context: workflow.context).filenames_to_stt
        end

        def whisper_options
          {
            options: {
              model: 'large',
              max_line_count: 80,
              beam_size: 10
            }
          }
        end
      end
    end
  end
end
