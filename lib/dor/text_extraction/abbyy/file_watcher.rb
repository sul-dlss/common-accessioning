# frozen_string_literal: true

require 'socket'
require 'active_support/core_ext/object/blank'

module Dor
  module TextExtraction
    module Abbyy
      # Watch jobs ABBYY is processing via the filesystem and report back to SDR
      # NOTE: in production, this class is run as a background process on the worker servers
      # See bin/abbyy_watcher for the script that starts this class
      # See lib/capistrano/tasks/abbyy_watcher_systemd.cap for the systemd service definition
      class FileWatcher
        attr_reader :result_xml_path, :exceptions_path, :logger, :workflow_updater

        # These methods control the underlying listener; see:
        # https://github.com/guard/listen?tab=readme-ov-file#pause--start--stop
        # NOTE: You need to `sleep` or otherwise avoid letting the process
        # exit after starting in order for the listener's thread to keep running
        delegate :start, :pause, :stop, to: :listener

        # rubocop:disable Metrics/AbcSize
        def initialize(
          logger: Logger.new($stdout),
          workflow_updater: Dor::TextExtraction::WorkflowUpdater,
          listener_options: {}
        )
          # Set up the ABBYY directories
          @result_xml_path = Settings.sdr.abbyy.local_result_path
          @exceptions_path = Settings.sdr.abbyy.local_exception_path
          raise ArgumentError, "ABBYY result XML path '#{result_xml_path}' is not a directory" unless File.directory?(result_xml_path)
          raise ArgumentError, "ABBYY exceptions path '#{exceptions_path}' is not a directory" unless File.directory?(exceptions_path)

          # Set up the services and listener
          @logger = logger
          @workflow_updater = workflow_updater.new(logger:)
          @listener_options = default_listener_options.merge(listener_options)
          Dor::Services::Client.configure(logger:, url: Settings.dor_services.url, token: Settings.dor_services.token)
        end
        # rubocop:enable Metrics/AbcSize

        private

        # See: https://github.com/guard/listen?tab=readme-ov-file#options
        def default_listener_options
          {
            only: /\.result\.xml$/,
            force_polling: false # Polling is required to access the Samba share
          }
        end

        # Controlled by the `start`, `pause`, and `stop` methods
        def listener
          @listener ||= Listen.to(result_xml_path, exceptions_path, **@listener_options) do |_modified, added, _removed|
            results = added.map { |path| Dor::TextExtraction::Abbyy::Results.new(result_path: path, logger: @logger) }
            successes, failures = results.partition(&:success?)
            successes.each(&method(:process_success))
            failures.each(&method(:process_failure))
          end
        end

        # Notify SDR that the OCR workflow step completed successfully
        def process_success(results)
          logger.info "Found successful OCR results for druid:#{results.druid} at #{results.result_path}"
          workflow_updater.mark_ocr_completed("druid:#{results.druid}")
          create_event(type: 'ocr_success', results:)
        end

        # Notify SDR that the OCR workflow step failed
        def process_failure(results)
          logger.info "Found failed OCR results for druid:#{results.druid} at #{results.result_path}: #{results.failure_messages.join('; ')}"
          context = { druid: "druid:#{results.druid}", result_path: results.result_path, failure_messages: results.failure_messages }
          Honeybadger.notify('Found failed OCR results', context:)
          workflow_updater.mark_ocr_errored("druid:#{results.druid}", error_msg: results.failure_messages.join("\n"))
          create_event(type: 'ocr_errored', results:)
        end

        # Publish to the SDR event service with processing information
        def create_event(type:, results:)
          Dor::Services::Client.object("druid:#{results.druid}").events.create(
            type:,
            data: {
              host:,
              invoked_by: 'abbyy_watcher',
              software_name: results.software_name,
              software_version: results.software_version,
              errors: results.failure_messages
            }.compact_blank
          )
        end

        def host
          @host ||= Socket.gethostname
        end
      end
    end
  end
end
