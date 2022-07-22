# frozen_string_literal: true

module Dor
  module Assembly
    module ContentMetadataFromStub
      # Builds a Cocina representation of the structural metadata
      class StructuralBuilder
        # Generates structural metadata for a repository object.
        #
        # @param [Cocina::Models::DRO] cocina_model
        # @param [Array<Array<Assembly::ObjectFile>>] objects the list of files to add to structural metadata
        # @param [String] reading_order ('left-to-right') only valid for books, can be 'right-to-left' or 'left-to-right'.
        def self.build(cocina_model:, objects:, reading_order: 'left-to-right')
          common_path = find_common_path(objects) # find common paths to all files provided

          filesets = objects.map { |resource_files| FileSet.new(resource_files: resource_files, cocina_model: cocina_model) }

          structural = {
            contains: build_filesets(filesets: filesets, cocina_model: cocina_model, common_path: common_path)
          }

          structural[:hasMemberOrders] = [{ viewingDirection: reading_order }] if cocina_model.type == Cocina::Models::ObjectType.book
          cocina_model.structural.new(structural)
        end

        def self.find_common_path(objects)
          all_paths = objects.flatten.map do |obj|
            raise "File '#{obj.path}' not found" unless obj.file_exists?

            obj.path # collect all of the filenames into an array
          end

          ::Assembly::ObjectFile.common_path(all_paths) # find common paths to all files provided if needed
        end
        private_class_method :find_common_path

        def self.administrative(file_attributes)
          {
            sdrPreserve: file_attributes[:preserve] == 'yes',
            publish: file_attributes[:publish] == 'yes',
            shelve: file_attributes[:shelve] == 'yes'
          }
        end
        private_class_method :administrative

        def self.build_filesets(filesets:, cocina_model:, common_path:)
          # a counter to use when creating auto-labels for resources, with incremenets for each type
          resource_type_counters = Hash.new(0)

          pid = cocina_model.externalIdentifier.delete_prefix('druid:') # remove druid prefix when creating IDs

          filesets.map.with_index(1) do |fileset, sequence| # iterate over all the resources
            file_set_type = fileset.file_set_type
            resource_type_counters[file_set_type] += 1 # each resource type description gets its own incrementing counter

            # create a generic resource label if needed
            default_label = "#{file_set_type.capitalize} #{resource_type_counters[file_set_type]}"

            contains = fileset.resource_files.map do |assembly_objectfile| # iterate over all the files in a resource
              build_file(assembly_objectfile: assembly_objectfile, cocina_model: cocina_model, common_path: common_path)
            end

            Cocina::Models::FileSet.new(
              externalIdentifier: "#{pid}_#{sequence}",
              label: fileset.label_from_file(default: default_label),
              type: Cocina::Models::FileSetType[file_set_type],
              version: cocina_model.version,
              structural: {
                contains: contains
              }
            )
          end
        end
        private_class_method :build_filesets

        def self.build_file(assembly_objectfile:, cocina_model:, common_path:)
          filename = assembly_objectfile.path.delete_prefix(common_path)

          file_attributes = {
            type: Cocina::Models::ObjectType.file,
            externalIdentifier: "https://cocina.sul.stanford.edu/file/#{SecureRandom.uuid}",
            label: filename,
            filename: filename,
            version: cocina_model.version,
            administrative: administrative(assembly_objectfile.file_attributes),
            access: Dor::FileSets.file_access(cocina_model.access)
          }
          file_attributes[:use] = assembly_objectfile.file_attributes[:role] if assembly_objectfile.file_attributes[:role]
          Cocina::Models::File.new(file_attributes)
        end
        private_class_method :build_file
      end
    end
  end
end
