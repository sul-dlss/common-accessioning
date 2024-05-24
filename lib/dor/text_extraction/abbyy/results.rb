# frozen_string_literal: true

module Dor
  module TextExtraction
    module Abbyy
      # Parses .xml.result.xml file that gets created when Abbyy sees a XMLTICKET
      class Results
        attr_reader :result_path, :druid, :run_index

        # Naming convention for result XML files:
        # ab123cd4567.xml.result.xml
        # ab123cd4567.xml.0001.result.xml
        RESULT_FILE_PATTERN = /(?<druid>\w+)\.xml(?:\.(?<run_index>\d+))?\.result\.xml/

        # Find the latest Abbyy results XML file by druid, since there coule be more than one.
        # @param druid [String] The druid to use to look for results
        # @param logger [Logger] An optional logger to use
        # @return [Results, nil] The Results object or nil, if one wasn't found.
        def self.find_latest(druid:, logger: nil)
          bare_druid = DruidTools::Druid.new(druid).id
          # NOTE: Dir.glob will sort the filenames in ascending order and we want the last one.
          result_files = Dir.glob("#{Settings.sdr.abbyy.local_result_path}/#{bare_druid}*.xml")
          Results.new(result_path: result_files.last, logger:) unless result_files.empty?
        end

        def initialize(result_path:, logger: nil)
          @result_path = result_path
          druid, run_index = RESULT_FILE_PATTERN.match(File.basename(result_path)).captures
          @druid = druid
          @run_index = (run_index || 0).to_i
          @logger = logger || Logger.new($stdout)
        end

        def success?
          xml_contents.at('@IsFailed').text == 'false'
        end

        def failure_messages
          errors = xml_contents.xpath("//Message[@Type='Error']//Text")
          errors&.map(&:text)
        end

        def output_docs
          output_docs = xml_contents.xpath('//OutputDocuments')
          {}.tap do |structural|
            output_docs.each do |doc|
              doc_type = doc.xpath('@ExportFormat').text.downcase
              structural[doc_type] = local_output_path(doc.xpath('@OutputLocation').text, doc.xpath('FileName').text)
            end
          end
        end

        def alto_doc
          output_docs['alto']
        end

        # write the result output files to a given directory
        def move_result_files(destination_dir)
          output_dir = Pathname.new(destination_dir)
          raise "Directory #{output_dir} doesn't exist, please make it first." unless output_dir.directory?

          paths = output_docs.values + split_ocr_paths
          paths.each do |path|
            dest_path = File.join(destination_dir, File.basename(path))
            @logger.info("moving #{path} to #{dest_path}")
            FileUtils.mv(path, dest_path)
          end
        end

        private

        # Return any Alto XML files in the output directory that have been split out from a larger one.
        def split_ocr_paths
          output_dir = local_output_dir(xml_contents.xpath('//OutputDocuments[1]/@OutputLocation').text)
          Dir.entries(output_dir)
             .filter { |filename| filename.match('_\d\d\d.xml$') }
             .map { |filename| File.join(output_dir, filename) }
        end

        def xml_contents
          @xml_contents ||= Nokogiri::XML(File.read(result_path))
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
      end
    end
  end
end
