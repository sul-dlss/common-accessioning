# frozen_string_literal: true

module Robots
  module DorRepo
    module SpeechToText
      # Process speech to text output files to remove problematic phrases
      class ProcessFiles < Dor::TextExtraction::Robot
        def initialize
          super('speechToTextWF', 'process-files')
        end

        # available from LyberCore::Robot: druid, bare_druid, workflow_service, object_client, cocina_object, logger
        def perform_work
          speech_to_text_filter = Dor::TextExtraction::SpeechToTextFilter.new

          # TODO: this assumes non-hierarchical files
          content_dir.children.each do |file|
            next unless process_file?(file)

            logger.info("processing #{file}")
            speech_to_text_filter.process(file)
          end
        end

        private

        # When processing speech to files, we will only include .vtt and .txt files
        def process_file?(file)
          %w[.vtt .txt].any? { |ext| file.basename.to_s.end_with?(ext) }
        end

        # content directory for the druid on the local workspace
        def content_dir
          Pathname.new(DruidTools::Druid.new(druid, Settings.sdr.local_workspace_root).content_dir)
        end
      end
    end
  end
end
