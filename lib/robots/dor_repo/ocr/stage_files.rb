# frozen_string_literal: true

module Robots
  module DorRepo
    module Ocr
      # Copy OCR files from ABBYY output folder to the workspace
      class StageFiles < LyberCore::Robot
        def initialize
          super('ocrWF', 'stage-files')
        end

        def perform_work
          workspace_dir = object_client.workspace.create(content: true, metadata: true)
          move_files(workspace_dir)
        end

        private

        def move_files(workspace_dir)
          content_dir = File.join(workspace_dir, 'content')

          result_path = Dor::TextExtraction::Abbyy::Results.find_latest(druid:)
          raise 'No ABBYY Result XML file found' unless result_path

          abbyy_results = Dor::TextExtraction::Abbyy::Results.new(result_path:, logger:)
          abbyy_results.move_result_files(content_dir)
        end
      end
    end
  end
end
