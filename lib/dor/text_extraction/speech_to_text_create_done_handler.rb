# frozen_string_literal: true

module Dor
  module TextExtraction
    # Handle an SQS message indicating that a speech-to-text job has completed (handles success or failure)
    class SpeechToTextCreateDoneHandler
      attr_reader :dor_event_logger, :host, :logger, :progname, :workflow_updater

      def initialize(host:, progname:, logger:)
        @host = host
        @progname = progname
        @logger = logger
        @workflow_updater = Dor::TextExtraction::WorkflowUpdater.new(logger:)
        @dor_event_logger = Dor::TextExtraction::DorEventLogger.new(logger:)
      end

      def process_done_message(done_msg)
        done_msg_hash = JSON.parse(done_msg.body)
        druid, _version = done_msg_hash['id'].split('-') # druid-version, e.g. bc123df4567-v2
        druid = DruidTools::Druid.new(druid).druid # normalize to namespaced druid, as DSA expects
        event_type = done_msg_hash['error'].blank? ? 'stt-create-success' : 'stt-create-error'

        update_workflow_step(druid:, create_succeeded: event_type == 'stt-create-success', error_msg: done_msg_hash['error'])
        send_to_dor_event_log(druid:, event_type:, done_msg_hash:)
      end

      private

      def update_workflow_step(druid:, create_succeeded:, error_msg: nil)
        if create_succeeded
          workflow_updater.mark_stt_create_completed(druid)
          logger.debug('process_done_message: stt-create workflow step marked completed')
        else
          workflow_updater.mark_stt_create_errored(druid, error_msg:)
          logger.debug("process_done_message: stt-create workflow step marked errored: #{error_msg}")
        end
      end

      def send_to_dor_event_log(druid:, event_type:, done_msg_hash:)
        data = {
          host:, invoked_by: progname, done_msg_body: done_msg_hash
        }
        dor_event_logger.create_event(druid:, type: event_type, data:)
        logger.debug("process_done_message: dor-services-app event created: #{{ druid:, event_type:, data: }}")
      end
    end
  end
end
