# frozen_string_literal: true

module Dor
  module TextExtraction
    # Update Cocina structural metadata with speech to text files files
    class SpeechToTextCocinaUpdater < CocinaUpdater
      private

      # we will skip .json speech to text files, these are only parsed for language to add to cocina
      def skip_file?(file)
        file.basename.to_s.start_with?('.') || file.basename.to_s.end_with?('.json')
      end

      def add_file_to_new_resource(_path)
        raise 'Dor::TextExtraction::SpeechToTextCocinaUpdater should not be creating new resources for speech to text files'
      end

      # parse the language from the json file (if found)
      def language(path)
        corresponding_json_file = find_workspace_file("#{stem(path)}.json")

        return unless corresponding_json_file

        json = JSON.parse(corresponding_json_file.read)
        json['language']
      end

      # set the use attribute based on the mimetype
      def use(object_file)
        case object_file.mimetype
        when 'text/plain'
          'transcription'
        when 'text/vtt'
          'caption'
        end
      end
    end
  end
end
