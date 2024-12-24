# frozen_string_literal: true

module Dor
  module TextExtraction
    # Post process the speech to text files by removing known problematic phrases
    # The phrases are stored in a yaml file `config/speech_to_text_filters.yaml`
    # and can be either strings or regexes
    class SpeechToTextFilter
      # Load the strings and regular expressions from the YAML file
      def filters
        @filters ||= YAML.load_file(Settings.speech_to_text.filter_file, permitted_classes: [Regexp])
      end

      def process(filename)
        # Read the content of the text file
        speech_to_text_output = File.read(filename)

        # Iterate through each pattern and remove matches from the text
        filters.each { |filter| speech_to_text_output.gsub!(filter, '') }

        # Output the cleaned text to the same file
        File.write(filename, speech_to_text_output)

        true
      end
    end
  end
end
