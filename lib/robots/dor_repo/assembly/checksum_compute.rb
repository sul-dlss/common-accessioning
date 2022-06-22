# frozen_string_literal: true

module Robots
  module DorRepo
    module Assembly
      class ChecksumCompute < Robots::DorRepo::Assembly::Base
        def initialize
          super('assemblyWF', 'checksum-compute')
        end

        def perform(druid)
          with_item(druid) do |assembly_item|
            cocina_model = assembly_item.cocina_model
            file_sets = compute_checksums(assembly_item, cocina_model)

            # Save the modified metadata
            updated = cocina_model.new(structural: cocina_model.structural.new(contains: file_sets))
            assembly_item.object_client.update(params: updated)
          end
        end

        private

        def compute_checksums(assembly_item, cocina_model)
          LyberCore::Log.info("Computing checksums for #{assembly_item.druid.id}")

          file_sets = cocina_model.structural.to_h.fetch(:contains) # make this a mutable hash

          file_sets.each do |file_set|
            files = file_set.dig(:structural, :contains)

            files.each do |file|
              object_file = ::Assembly::ObjectFile.new(assembly_item.path_finder.path_to_content_file(file.fetch(:filename)))

              # compute checksums
              checksums = { md5: object_file.md5, sha1: object_file.sha1 }

              # find any existing checksum nodes
              md5_node = file[:hasMessageDigests].find { |digest| digest[:type] == 'md5' }
              sha1_node = file[:hasMessageDigests].find { |digest| digest[:type] == 'sha1' }

              # if we have any existing checksum nodes, compare them all against the checksums we just computed, and raise an error if any fail
              if md5_node
                raise %(Checksums disagree: type="md5", file="#{fn['id']}", computed="#{checksums[:md5]}, provided="#{md5_node[:digest]}".) unless checksums_equal?(md5_node, checksums[:md5])
              else
                file[:hasMessageDigests] << { type: 'md5', digest: checksums[:md5] }
              end
              if sha1_node
                raise %(Checksums disagree: type="sha1", file="#{fn['id']}", computed="#{checksums[:sha1]}", provided="#{sha1_node[:digest]}".) unless checksums_equal?(sha1_node, checksums[:sha1])
              else
                file[:hasMessageDigests] << { type: 'sha1', digest: checksums[:sha1] }
              end
            end
          end

          file_sets
        end

        # compare existing checksum nodes with computed checksum, return false if there are any mismatches, otherwise return true
        def checksums_equal?(existing_checksum_node, computed_checksum)
          existing_checksum_node[:digest].casecmp(computed_checksum).zero?
        end
      end
    end
  end
end
