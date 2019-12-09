# frozen_string_literal: true

module Robots
  module DorRepo
    module Assembly
      class ChecksumCompute < Robots::DorRepo::Assembly::Base
        def initialize(opts = {})
          super('dor', 'assemblyWF', 'checksum-compute', opts)
        end

        def perform(druid)
          with_item(druid) do |assembly_item|
            compute_checksums(assembly_item)
          end
        end

        private

        def compute_checksums(assembly_item)
          LyberCore::Log.info("Computing checksums for #{assembly_item.druid.id}")

          # Get the object we'll use to compute checksums.

          # Process each <file> node in the content metadata.
          assembly_item.file_nodes.each do |fn|
            # Compute checksums.
            obj = ::Assembly::ObjectFile.new(assembly_item.path_finder.path_to_content_file(fn['id']))

            # compute checksums
            checksums = { md5: obj.md5, sha1: obj.sha1 }

            # find any existing checksum nodes
            md5_nodes = fn.xpath('checksum[@type="md5"]')
            sha1_nodes = fn.xpath('checksum[@type="sha1"]')

            # if we have any existing checksum nodes, compare them all against the checksums we just computed, and raise an error if any fail
            if !md5_nodes.empty?
              raise %(Checksums disagree: type="md5", file="#{fn['id']}", computed="#{checksums[:md5]}, provided="#{md5_nodes.first}".) unless checksums_equal?(md5_nodes, checksums[:md5])
            else
              add_checksum_node assembly_item, fn, 'md5', checksums[:md5]
            end
            if !sha1_nodes.empty?
              raise %(Checksums disagree: type="sha1", file="#{fn['id']}", computed="#{checksums[:sha1]}", provided="#{sha1_nodes.first}".) unless checksums_equal?(sha1_nodes, checksums[:sha1])
            else
              add_checksum_node assembly_item, fn, 'sha1', checksums[:sha1]
            end
          end

          # Save the modified XML.
          assembly_item.persist_content_metadata
        end

        # compare existing checksum nodes with computed checksum, return false if there are any mismatches, otherwise return true
        def checksums_equal?(existing_checksum_nodes, computed_checksum)
          match = true
          existing_checksum_nodes.each { |checksum| match = false unless checksum.content.casecmp(computed_checksum).zero? }
          match
        end

        def add_checksum_node(assembly_item, parent_node, checksum_type, checksum)
          cn         = assembly_item.new_node_in_cm 'checksum'
          cn.content = checksum
          cn['type'] = checksum_type
          parent_node.add_child cn
        end
      end
    end
  end
end
