# frozen_string_literal: true

module Dor
  module TextExtraction
    module Abbyy
      # Watch jobs ABBYY is processing via the filesystem and report back to SDR
      class FileWatcher
        attr_reader :result_xml_path, :exceptions_path

        # These methods control the underlying listener; see:
        # https://github.com/guard/listen?tab=readme-ov-file#pause--start--stop
        # NOTE: You need to `sleep` or otherwise avoid letting the process
        # exit after starting in order for the listener's thread to keep running
        delegate :start, :pause, :stop, to: :listener

        def initialize(workflow_updater: nil, listener_options: {})
          @result_xml_path = Settings.sdr.abbyy_result_path
          @exceptions_path = Settings.sdr.abbyy_exception_path

          # Ensure the ABBYY directories exist
          raise ArgumentError, "ABBYY result XML path '#{result_xml_path}' is not a directory" unless File.directory?(result_xml_path)
          raise ArgumentError, "ABBYY exceptions path '#{exceptions_path}' is not a directory" unless File.directory?(exceptions_path)

          # Set up the workflow updater and listener
          @workflow_updater = workflow_updater || Dor::TextExtraction::WorkflowUpdater.new
          @listener_options = default_listener_options.merge(listener_options)
        end

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
          @workflow_updater.mark_ocr_completed(results.druid)
        end

        # Notify SDR that the OCR workflow step failed
        def process_failure(results)
          @workflow_updater.mark_ocr_errored(results.druid)
        end
      end
    end
  end
end
