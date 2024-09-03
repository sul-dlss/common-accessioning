# frozen_string_literal: true

module Dor
  module TextExtraction
    module Abbyy
      # Parses .xml.result.xml file that gets created when Abbyy sees a XMLTICKET
      class Results
        attr_reader :result_path, :druid, :software_name, :software_version, :success, :file_list, :failure_messages

        # Naming convention for result XML files:
        # ab123cd4567.xml.result.xml
        # ab123cd4567.xml.0001.result.xml
        RESULT_FILE_PATTERN = /(?<druid>\w+)\.xml(?:\.(?<run_index>\d+))?\.result\.xml/

        # Find the latest Abbyy results XML file by druid, since there could be more than one.
        # @param druid [String] The druid to use to look for results
        # @return [xml_filepath, nil] The result xml file path or nil, if one wasn't found.
        def self.find_latest(druid:)
          bare_druid = DruidTools::Druid.new(druid).id
          # NOTE: Dir.glob will sort the filenames in ascending order and we want the last one.
          Dir.glob("#{Settings.sdr.abbyy.local_result_path}/#{bare_druid}*.xml").last
        end

        def initialize(result_path:, logger: nil)
          @result_path = result_path
          druid, _run_index = RESULT_FILE_PATTERN.match(File.basename(result_path)).captures
          @druid = druid
          @logger = logger || Logger.new($stdout)
          @file_list = []
          @failure_messages = []
          @software_name = 'ABBYY FineReader Server'
          parse_xml
        end

        def output_docs
          {}.tap do |structural|
            file_list.each do |doc|
              structural[doc['ExportFormat'].downcase] = local_output_path(doc['OutputLocation'], doc['FileName'])
            end
          end
        end

        def alto_doc
          output_docs['alto']
        end

        def success?
          success
        end

        # write the result output files to a given directory
        def move_result_files(destination_dir)
          output_dir = Pathname.new(destination_dir)
          raise "Directory #{output_dir} doesn't exist, please make it first." unless output_dir.directory?

          paths_to_move.each do |path|
            dest_path = File.join(destination_dir, File.basename(path))
            @logger.info("moving #{path} to #{dest_path}")
            FileUtils.mv(path, dest_path)
          end
        end

        private

        # Return all the output file paths that need to be moved.
        # NOTE: the multiple page Abbyy OCR file is NOT accessioned.
        def paths_to_move
          paths = (output_docs.values + split_ocr_paths).uniq
          paths.reject { |path| path.end_with?("#{druid}.xml") }
        end

        # Return any Alto XML files in the output directory that have been split out from a larger one.
        def split_ocr_paths
          output_dir = local_output_dir(file_list.first['OutputLocation'])
          Dir.entries(output_dir)
             .filter { |filename| filename.match('.+\.xml$') }
             .map { |filename| File.join(output_dir, filename) }
        end

        def parse_xml
          reader = Nokogiri::XML::Reader(File.read(result_path))
          reader.each do |node|
            get_file_data(node) if node.attributes.keys.include?('ExportFormat')
            failures(node) if node.name == 'Message'
            get_status(node) if node.attributes.keys.include?('IsFailed')
          end
          processing_metadata
        end

        def failures(node)
          return unless node.attributes['Type'] == 'Error'

          text = node_text(node)
          return unless text

          @failure_messages.push(node_text(node))
        end

        def get_status(node)
          @success = node.attributes['IsFailed'] == 'false'
        end

        def get_file_data(node)
          doc_data = node.attributes
          doc_data['FileName'] = node_text(node)
          @file_list.push(doc_data) if doc_data['FileName']
        end

        def node_text(node)
          @node_text = Nokogiri::XML(node.inner_xml).text
          return false unless @node_text.present?

          @node_text
        end

        # Return the local Unix path for a given Abbyy Windows output directory
        # and filename as found in the Abbyy output XML.
        def local_output_path(windows_dir, filename)
          File.join(local_output_dir(windows_dir), filename)
        end

        # Return the local Unix path for the Abbyy Windows output directory
        def local_output_dir(windows_dir)
          windows_dir.sub(Settings.sdr.abbyy.remote_output_path, Settings.sdr.abbyy.local_output_path)
        end

        # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        # Software and version used to do OCR processing, found in ALTO output
        def processing_metadata
          return {} unless File.exist? alto_doc # PDFs don't have ALTO, so just bail out

          Nokogiri::XML::Reader(File.read(alto_doc)).each do |node|
            next unless node.name == 'processingSoftware'

            metadata = Nokogiri::XML(node.outer_xml)
            next unless metadata.at('softwareVersion')

            @software_name = metadata.at('softwareName').text
            @software_version = metadata.at('softwareVersion').text
            break
          end
        rescue StandardError # If we can't parse the ALTO, log it and move on
          Honeybadger.notify('Failed to parse processing metadata from ALTO XML', context: { alto_doc: })
          {}
        end
        # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
      end
    end
  end
end
