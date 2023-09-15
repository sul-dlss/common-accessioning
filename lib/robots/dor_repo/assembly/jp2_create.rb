# frozen_string_literal: true

module Robots
  module DorRepo
    module Assembly
      class Jp2Create < Robots::DorRepo::Assembly::Base
        def initialize
          super('assemblyWF', 'jp2-create')
        end

        def perform_work
          return unless check_assembly_item

          cocina_model = assembly_item.cocina_model
          return LyberCore::ReturnState.new(status: :skipped, note: 'object is dark, no derivatives required') if cocina_model.access.view == 'dark'

          file_sets = create_jp2s(assembly_item, cocina_model)
          # Save the modified metadata
          updated = cocina_model.new(structural: cocina_model.structural.new(contains: file_sets))
          assembly_item.object_client.update(params: updated)
        end

        private

        # For each supported image type that is part of specific resource types, generate a jp2 derivative
        # and modify structural metadata to reflect the new file.
        # rubocop:disable Metrics/PerceivedComplexity
        def create_jp2s(assembly_item, cocina_model)
          logger.info("Creating JP2s for #{assembly_item.druid.id}")
          file_sets = cocina_model.structural.to_h.fetch(:contains) # make this a mutable hash
          file_sets.each do |file_set|
            next if skip_fileset?(file_set)

            cocina_files = file_set.dig(:structural, :contains)

            new_cocina_files = cocina_files.dup
            cocina_files.each do |cocina_file|
              # If the file cocina file has a mimetype and it is not jp2able, skip it
              next if skip_cocina_file?(cocina_file)

              filename = cocina_file.fetch(:filename)
              filepath = filepath_for(filename, assembly_item)

              # If the file exists and it is not jp2able, skip it
              next if skip_file?(filepath)

              assembly_image = assembly_image_for(filepath)
              jp2_filename = jp2_filename_for(filename, assembly_image)
              jp2_filepath = filepath_for(jp2_filename, assembly_item)

              cocina_jp2_file = find_cocina_jp2_file(cocina_files)

              # If the file exists and there is a jp2 cocina file, skip it
              next if File.exist?(filepath) && File.exist?(jp2_filepath) && cocina_jp2_file.present?

              # If the file does not exist and there is a jp2 cocina file, skip it
              next if !File.exist?(filepath) && cocina_jp2_file.present?

              # If the file does not exist and there is no jp2 cocina file, get it from preservation
              retrieve_from_preservation(assembly_item.druid.id, filename, filepath) unless File.exist?(filepath)

              # If the file exists and there is no jp2 file or there is no jp2 cocina file, delete existing jp2 cocina file, delete existing jp2 file, generate jp2, and add new jp2 cocina file
              if File.exist?(filepath) && (!File.exist?(jp2_filepath) || cocina_jp2_file.blank?)
                delete_file(jp2_filepath)
                delete_cocina_file(cocina_jp2_file, new_cocina_files)
                create_jp2_file(assembly_image)
                create_cocina_jp2_file(jp2_filename, cocina_model, new_cocina_files)
                next
              end

              raise NotImplementedError, "Unhandled condition for #{filename}. This indicates a gap in the robot code."
            end
            file_set[:structural][:contains] = new_cocina_files
          end

          file_sets
        end
        # rubocop:enable Metrics/PerceivedComplexity

        def find_cocina_jp2_file(cocina_files)
          cocina_files.find { |cocina_file| cocina_file[:filename].ends_with?('.jp2') }
        end

        def filepath_for(filename, assembly_item)
          assembly_item.path_finder.path_to_content_file(filename)
        end

        def jp2_filename_for(filename, assembly_image)
          filename.gsub(File.basename(assembly_image.path), File.basename(assembly_image.jp2_filename))
        end

        def skip_fileset?(file_set)
          [Cocina::Models::FileSetType.page, Cocina::Models::FileSetType.image].exclude?(file_set.fetch(:type))
        end

        def skip_cocina_file?(cocina_file)
          cocina_file[:hasMimeType].present? && ::Assembly::VALID_IMAGE_MIMETYPES.exclude?(cocina_file[:hasMimeType])
        end

        def skip_file?(filepath)
          File.exist?(filepath) && !::Assembly::ObjectFile.new(filepath).jp2able?
        end

        def assembly_image_for(filepath)
          object_file = ::Assembly::ObjectFile.new(filepath)
          ::Assembly::Image.new(object_file.path)
        end

        def delete_file(filepath)
          FileUtils.rm_f(filepath)
        end

        def delete_cocina_file(cocina_file, new_cocina_files)
          new_cocina_files.delete(cocina_file) if cocina_file.present?
        end

        def create_jp2_file(assembly_image)
          assembly_image.create_jp2(overwrite: false, tmp_folder: Settings.assembly.tmp_folder)
        end

        def create_cocina_jp2_file(filename, cocina_model, new_cocina_files)
          new_cocina_files << {
            type: 'https://cocina.sul.stanford.edu/models/file',
            externalIdentifier: "https://cocina.sul.stanford.edu/file/#{SecureRandom.uuid}",
            version: cocina_model.version,
            label: filename,
            filename:,
            hasMessageDigests: [],
            hasMimeType: 'image/jp2',
            administrative: { sdrPreserve: false, publish: true, shelve: true },
            access: Dor::FileSets.file_access(cocina_model.access)
          }
        end

        def retrieve_from_preservation(druid, filename, filepath)
          File.open(filepath, 'wb') do |file_writer|
            preservation_client.objects.content(druid:,
                                                filepath: filename,
                                                on_data: proc { |data, _count| file_writer.write data })
          end
        end

        def preservation_client
          @preservation_client ||= Preservation::Client.configure(url: Settings.preservation_catalog.url, token: Settings.preservation_catalog.token)
        end
      end
    end
  end
end
