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
          # start the caption creation by sending Batch a job
          send_batch_message

          # Leave this step running until the Whisper monitoring job marks it as complete
          LyberCore::ReturnState.new(status: :noop, note: 'Initiated SpeechToText.')
        rescue StandardError => e
          Honeybadger.notify('Problem sending Batch job to AWS for SpeechToText', context: { druid:, job_id:, error: e })
          raise "Error sending Batch job: #{e.message}"
        end

        private

        def send_batch_message
          # Send the message to the Batch
          aws_provider.submit_job(message)

          logger.info("Sent Batch job for druid #{druid} to Batch job_queue=#{aws_provider.batch_job_queue} with job_definition=#{aws_provider.batch_job_definition} and job_id=#{job_id}")
        end

        def message
          {
            id: job_id,
            druid:,
            media:
          }.merge(whisper_options)
        end

        def job_id
          stt.job_id
        end

        # array of media files in the bucket folder for this job (excluding s3 folders)
        def media
          filenames = aws_provider.client.list_objects(bucket: aws_provider.bucket_name, prefix: job_id).contents.map(&:key).reject { |key| key.end_with?('/') }
          filenames.map do |filename|
            media_file = { name: filename }
            language_tag = stt.language_tag(File.basename(filename))
            media_file[:options] = { language: language_tag } if language_tag
            media_file
          end
        end

        # pulled from config, could later be overriden by settings in the workflow context
        def whisper_options
          Settings.speech_to_text.whisper.to_h
        end

        def stt
          @stt ||= Dor::TextExtraction::SpeechToText.new(cocina_object:)
        end
      end
    end
  end
end
