# frozen_string_literal: true

module Dor
  module TextExtraction
    module Abbyy
      # Watch jobs ABBYY is processing via the filesystem and report back to SDR
      # NOTE: in production, this class is run as a background process on the worker servers
      # See bin/abbyy_watcher for the script that starts this class
      # See lib/capistrano/tasks/abbyy_watcher_systemd.cap for the systemd service definition
      class FileWatcher
        attr_reader :result_xml_path, :exceptions_path

        # These methods control the underlying listener; see:
        # https://github.com/guard/listen?tab=readme-ov-file#pause--start--stop
        # NOTE: You need to `sleep` or otherwise avoid letting the process
        # exit after starting in order for the listener's thread to keep running
        delegate :start, :pause, :stop, to: :listener

        # rubocop:disable Metrics/AbcSize
        def initialize(logger: nil, workflow_updater: nil, listener_options: {})
          @result_xml_path = Settings.sdr.abbyy.local_result_path
          @exceptions_path = Settings.sdr.abbyy.local_exception_path

          # Ensure the ABBYY directories exist
          raise ArgumentError, "ABBYY result XML path '#{result_xml_path}' is not a directory" unless File.directory?(result_xml_path)
          raise ArgumentError, "ABBYY exceptions path '#{exceptions_path}' is not a directory" unless File.directory?(exceptions_path)

          # Set up the workflow updater and listener
          @logger = logger || Logger.new($stdout)
          @workflow_updater = workflow_updater || Dor::TextExtraction::WorkflowUpdater.new
          @listener_options = default_listener_options.merge(listener_options)
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
            results = added.map { |path| Dor::TextExtraction::Abbyy::Results.new(result_path: path) }
            successes, failures = results.partition(&:success?)
            successes.each(&method(:process_success))
            failures.each(&method(:process_failure))
          end
        end

        # Notify SDR that the OCR workflow step completed successfully
        def process_success(results)
          @logger.info "Found successful OCR results for druid:#{results.druid} at #{results.result_path}"
          @workflow_updater.mark_ocr_completed("druid:#{results.druid}")
        end

        # Notify SDR that the OCR workflow step failed
        def process_failure(results)
          @logger.info "Found failed OCR results for druid:#{results.druid} at #{results.result_path}: #{results.failure_messages.join('; ')}"
          context = { druid: "druid:#{results.druid}", result_path: results.result_path, failure_messages: results.failure_messages }
          Honeybadger.notify('Found failed OCR results', context:)
          @workflow_updater.mark_ocr_errored("druid:#{results.druid}", error_msg: results.failure_messages.join("\n"))
        end
      end
    end
  end
end
