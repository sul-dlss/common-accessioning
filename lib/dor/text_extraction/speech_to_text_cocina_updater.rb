# frozen_string_literal: true

module Dor
  module TextExtraction
    # Update Cocina structural metadata with speech to text files files
    class SpeechToTextCocinaUpdater < CocinaUpdater
      private

      # When adding files to the object, we will skip everything except .vtt, .txt and .json files
      def include_file?(file)
        %w[.vtt .txt .json].any? { |ext| file.basename.to_s.end_with?(ext) }
      end

      def add_file_to_new_resource(_path)
        raise 'Dor::TextExtraction::SpeechToTextCocinaUpdater should not be creating new resources for speech to text files'
      end

      # parse the language from the json file (if found)
      def language(path)
        corresponding_json_file = find_workspace_file("#{stem(path)}.json")

        raise "missing expected json file: '#{corresponding_json_file}'" unless corresponding_json_file

        json = JSON.parse(corresponding_json_file.read)
        json['language']
      end

      # set the administrative attributes based on the mimetype
      # all speech to text files are preserved, shelved and published EXCEPT json files, which are only preserved
      def administrative(object_file)
        preserve = true
        publish = shelve = object_file.mimetype != 'application/json'
        {
          publish:,
          sdrPreserve: preserve,
          shelve:
        }
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
