# frozen_string_literal: true

require 'systemu'

module EtdSubmit
  module TransferUtils
    #
    # This method returns the augmented pdf for the given identifier.  Files that are ready to be transferred to the
    # google dropbox location will have their 'deliver' status set to 'yes' in their contentMetadata datastreams and
    # contain the phrase '-augmented.pdf' in the filename.
    #
    def get_augmented_pdf_filename(pid)
      pair_tree = DruidTools::PurlDruid.new(pid, DIGITAL_STACKS_STORAGE_ROOT)
      file_path = File.join(pair_tree.content_dir, '*-augmented.pdf')
      file = Dir.glob(file_path).first
      raise "Augmented File error -- Unable to find #{file_path}." unless file

      file
    end
  end
end
