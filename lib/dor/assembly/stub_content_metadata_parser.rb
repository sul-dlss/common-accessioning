# frozen_string_literal: true

module Dor
  module Assembly
    # Parses the stub content metadata file
    # stubContentMetadata.xml is created by Goobi with a skeleton of what will
    # eventually be the contentMetadata.xml. It contains just enough information
    # before our robots fill in the rest.
    module StubContentMetadataParser
      # BEWARE: This depends on the @druid ivar and druid method
      def convert_stub_content_metadata
        # uses the assembly-objectfile gem to create content metadata using the stub contentMetadata provided
        load_stub_content_metadata

        cm_resources = resources.map do |resource| # loop over all resources from the stub content metadata
          resource_files(resource).map do |file| # loop over the files in this resource
            obj_file = ::Assembly::ObjectFile.new(File.join(path_finder.path_to_content_folder, filename(file)))
            obj_file.file_attributes = Dor::FileSets.default_administrative_attributes(obj_file.mimetype, object_access: cocina_model.access).merge(stub_file_attributes(file))
            obj_file.label = resource_label(resource)
            obj_file
          end
        end

        ContentMetadataFromStub::StructuralBuilder.build(cocina_model: cocina_model, objects: cm_resources, reading_order: book_reading_order)
      end

      def stub_content_metadata_exists?
        # indicate if a stub contentMetadata file exists
        File.exist?(stub_cm_file_name)
      end

      # return the location to read the stubContentMetadata.xml file from (could be in either the new or old location)
      def stub_cm_file_name
        @stub_cm_file_name ||= path_finder.path_to_metadata_file(Settings.assembly.stub_cm_file_name)
      end

      def load_stub_content_metadata
        # Loads stub content metadata XML into a Nokogiri document.
        raise "Stub content metadata file #{Settings.assembly.stub_cm_file_name} not found for #{druid.id} in any of the root directories: #{@root_dir.join(',')}" unless stub_content_metadata_exists?

        @stub_cm = Nokogiri.XML(File.open(stub_cm_file_name)) { |conf| conf.default_xml.noblanks }
      end

      # this determines the reading order from the stub_object_type (default ltr unless the object type contains one of the possible "rtl" designations)
      def book_reading_order
        return 'right-to-left' if stub_object_type.include?('rtl') || stub_object_type.include?('r-l')

        'left-to-right'
      end

      def stub_object_type
        node = @stub_cm.xpath('/content/@type')
        node.empty? ? nil : node.first.value.downcase.strip
      end

      def resources
        @stub_cm.xpath('//resource')
      end

      def resource_label(resource)
        node = resource.css('/label')
        node.empty? ? '' : node.first.content
      end

      def resource_files(resource)
        resource.css('/file')
      end

      def filename(file)
        file.at_xpath('@name').value
      end

      # return a hash for any known file attributes defined in the stub content metadata file, these will override or add to the defaults
      def stub_file_attributes(file)
        result = {}
        %w[preserve publish shelve role].each { |attribute| result[attribute.to_sym] = file.at_xpath("@#{attribute}").value unless file.at_xpath("@#{attribute}").blank? }
        result
      end
    end
  end
end
