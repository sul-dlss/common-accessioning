# frozen_string_literal: true

module Dor
  module Assembly
    class ContentMetadata
      # Builds a nokogiri representation of the content metadata
      class NokogiriBuilder
        # @param [Array<Fileset>] filesets
        # @param [String] druid
        # @param [String] common_path
        # @param [Config] config
        def self.build(filesets:, druid:, common_path:, config:)
          # a counter to use when creating auto-labels for resources, with incremenets for each type
          resource_type_counters = Hash.new(0)
          pid = druid.gsub('druid:', '') # remove druid prefix when creating IDs

          Nokogiri::XML::Builder.new do |xml|
            xml.contentMetadata(objectId: druid.to_s, type: config.type) do
              xml.bookData(readingOrder: config.reading_order) if config.type == 'book'

              filesets.each_with_index do |fileset, index| # iterate over all the resources
                # start a new resource element
                sequence = index + 1

                resource_type_counters[fileset.resource_type_description] += 1 # each resource type description gets its own incrementing counter

                xml.resource(id: "#{pid}_#{sequence}", sequence: sequence, type: fileset.resource_type_description) do
                  # create a generic resource label if needed
                  default_label = config.auto_labels ? "#{fileset.resource_type_description.capitalize} #{resource_type_counters[fileset.resource_type_description]}" : ''

                  # but if one of the files has a label, use it instead
                  resource_label = fileset.label_from_file(default: default_label)

                  xml.label(resource_label) unless resource_label.empty?
                  fileset.files.each do |cm_file| # iterate over all the files in a resource
                    xml_file_params = { id: cm_file.file_id(common_path: common_path) }
                    xml_file_params.merge!(cm_file.file_attributes(config.file_attributes))

                    xml.file(xml_file_params)
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
