# frozen_string_literal: true

module Dor
  module TextExtraction
    # Update Cocina structural metadata with speech to text files files
    class SpeechToTextCocinaUpdater < CocinaUpdater
      private

      # set the use attribute based on the mimetype
      def use(object_file)
        case object_file.mimetype
        when 'text/plain'
          'transcription'
        when 'text/vtt'
          'caption'
        end
      end

      def resource_label(path)
        extension = path.extname
        raise "Unable to determine resource label for #{path}" unless extension == '.txt'

        'Transcript'
      end
    end
  end
end
