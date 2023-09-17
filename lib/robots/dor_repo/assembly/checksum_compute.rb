# frozen_string_literal: true

module Robots
  module DorRepo
    module Assembly
      class ChecksumCompute < Robots::DorRepo::Assembly::Base
        def initialize
          super('assemblyWF', 'checksum-compute')
        end

        def perform_work
          return unless check_assembly_item

          cocina_model = assembly_item.cocina_model
          logger.info("Computing checksums for #{druid}")
          file_sets = compute_checksums(assembly_item, cocina_model)

          # Save the modified metadata
          updated = cocina_model.new(structural: cocina_model.structural.new(contains: file_sets))
          assembly_item.object_client.update(params: updated)
        end

        private

        def compute_checksums(assembly_item, cocina_model)
          file_sets = cocina_model.structural.to_h.fetch(:contains) # make this a mutable hash

          file_sets.each do |file_set|
            files = file_set.dig(:structural, :contains)
            files.each do |file|
              compute_checksum(assembly_item, file)
            end
          end

          file_sets
        end

        def compute_checksum(assembly_item, file)
          # find any existing checksum nodes
          md5_node = file[:hasMessageDigests].find { |digest| digest[:type] == 'md5' }
          sha1_node = file[:hasMessageDigests].find { |digest| digest[:type] == 'sha1' }

          filepath = assembly_item.path_finder.path_to_content_file(file.fetch(:filename))

          # File is not changing, so use existing checksums
          return if md5_node && sha1_node && !File.exist?(filepath)

          # compute checksums
          checksums = generate_checksums(filepath)

          # if we have any existing checksum nodes, compare them all against the checksums we just computed, and raise an error if any fail
          if md5_node
            raise %(Checksums disagree: type="md5", file="#{file[:filename]}", computed="#{checksums[:md5]}, provided="#{md5_node[:digest]}".) unless checksums_equal?(md5_node, checksums[:md5])
          else
            file[:hasMessageDigests] << { type: 'md5', digest: checksums[:md5] }
          end
          if sha1_node
            raise %(Checksums disagree: type="sha1", file="#{file[:filename]}", computed="#{checksums[:sha1]}", provided="#{sha1_node[:digest]}".) unless checksums_equal?(sha1_node, checksums[:sha1])
          else
            file[:hasMessageDigests] << { type: 'sha1', digest: checksums[:sha1] }
          end
        end

        # compare existing checksum nodes with computed checksum, return false if there are any mismatches, otherwise return true
        def checksums_equal?(existing_checksum_node, computed_checksum)
          existing_checksum_node[:digest].casecmp(computed_checksum).zero?
        end

        def generate_checksums(filepath)
          md5 = Digest::MD5.new
          sha1 = Digest::SHA1.new
          File.open(filepath, 'r') do |stream|
            while (buffer = stream.read(8192))
              md5.update(buffer)
              sha1.update(buffer)
            end
          end
          { md5: md5.hexdigest, sha1: sha1.hexdigest }
        end
      end
    end
  end
end
