# frozen_string_literal: true

require 'csv'
require 'fileutils'
require 'net/sftp'

# Indexes from etd report
# 0: 0000002198
# 1: druid:qn846kw9589
# 2: http://purl.stanford.edu/qn846kw9589
# 3: 9861765
# 4: http://searchworks.stanford.edu/view/9861765
# 5: dissertation
# 6: School of Medicine
# 7: Genetics
# 8: Foley, Joseph William
# 9: Transcription-factor "occupancy" at HOT regions quantitatively predicts RNA polymerase recruitment in five human cell lines
# 10: https://stacks.stanford.edu/file/druid:qn846kw9589/dissertation-jwfoley_esubmit-augmented.pdf
# 11: by-nc-sa
# 12: 1 year
# 13: 2014-01-09
# 14: 100%

module Robots
  module DorRepo
    module EtdSubmit
      EtdInfo = Struct.new(:content_file, :druid, :file_name, :student_name, :title, :catkey)

      class EtdInfo
        @header_map = {}

        # Create lookup map between column-name to index number.  Allows parsing of report rows by column-name
        #  i.e. { 'student name' => 8 }
        # @param [String] header first line from the etd report, containing the column headers
        # @return [Hash] map from column-name to index number
        def self.parse_header(header)
          @header_map = {}
          cols = header.strip.split('|')
          (0..(cols.size - 1)).each do |i|
            @header_map[cols[i]] = i
          end
          @header_map
        end

        # @param [String] row line from the etd report
        # @return [EtdInfo] the object as parsed from the row
        def self.parse_row(row)
          fields = row.strip.split('|')
          etd = EtdInfo.new
          etd.druid = fields[@header_map['druid']]
          etd.student_name = fields[@header_map['student name']]
          etd.title = fields[@header_map['title']]
          etd.catkey = fields [@header_map['catkey']].strip
          etd
        end
      end

      class BinderBatchTransfer
        include ::EtdSubmit::TransferUtils

        # @param [String] report_file path to a pipe-delimited report from https://etd.stanford.edu/reports
        # @param [String] binder_quarter_root path to the binder dropoff directory for the quarter
        def initialize(report_file, binder_quarter_root)
          raise 'Needs path to report file' if report_file.nil?

          LyberCore::Log.set_logfile("#{ROBOT_ROOT}/log/binder-batch-transfer.log")
          LyberCore::Log.set_level(1)

          @report_file = report_file
          @binder_list = []
          @binder_storage_root = binder_quarter_root
        end

        def process_druids
          LyberCore::Log.info('Setting up content to send to binder')
          lines = IO.readlines(@report_file)
          EtdInfo.parse_header lines.shift
          lines.each do |line|
            etd = EtdInfo.parse_row(line)
            if etd.catkey.empty?
              LyberCore::Log.warn("Skipping #{etd.druid}: no catkey")
              next
            end

            begin
              LyberCore::Log.info("Fetching content for #{etd.druid}")
              etd.content_file = get_augmented_pdf_filename(etd.druid)
            rescue StandardError => e
              LyberCore::Log.error("#{e.inspect}\n" << e.backtrace.join("\n") << "\n!!!!!!!!!!!!!!!!!!")
              workflow_error etd.druid, e
              next
            end

            @binder_list << etd
          end

          send_to_binder
        end

        def send_to_binder
          Net::SFTP.start(BINDER_DROPBOX_HOST, BINDER_DROPBOX_USER) do |sftp|
            successful = []

            # Transfer pdfs to the binder
            @binder_list.each do |etd|
              etd.file_name = "#{etd.druid.split(':').last}.pdf"
              LyberCore::Log.info("Transferring #{etd.druid} to binder")
              sftp.upload!(etd.content_file, @binder_storage_root + '/' + etd.file_name)
              workflow_success etd.druid
              successful << etd
            rescue StandardError => e
              LyberCore::Log.error("#{e.inspect}\n" << e.backtrace.join("\n") << "\n!!!!!!!!!!!!!!!!!!")
              workflow_error etd.druid, e
              next
            end

            LyberCore::Log.info('Building and sending CSV report')
            # Using the same connection, build and send the report of successfully sent ETDs
            CSV.open("#{ROBOT_ROOT}/log/report.csv", 'w') do |csv|
              csv << ['file-name', 'student-name', 'dissertation-title']
              successful.each { |etd| csv << [etd.file_name, etd.student_name, etd.title] }
            end

            sftp.upload!("#{ROBOT_ROOT}/log/report.csv", @binder_storage_root + '/report.csv')
          end
        end

        def workflow_success(druid)
          Dor::Config.workflow.client.update_workflow_status 'dor', druid, 'etdSubmitWF', 'binder-transfer', 'completed'
        rescue StandardError => err
          LyberCore::Log.error("Unable to set workflow for #{druid}")
          LyberCore::Log.error(err.inspect.to_s)
        end

        def workflow_error(druid, error)
          Dor::Config.workflow.client.update_workflow_error_status 'dor', druid, 'etdSubmitWF', 'binder-transfer', error.inspect
        rescue StandardError => err
          LyberCore::Log.error("Unable to set workflow to error for #{druid}")
          LyberCore::Log.error(err.inspect.to_s)
        end
      end
    end
  end
end
