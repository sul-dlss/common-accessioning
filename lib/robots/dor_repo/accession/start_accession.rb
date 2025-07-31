# frozen_string_literal: true

module Robots
  module DorRepo
    module Accession
      # Kicks off accessioning by making sure the item is not open
      class StartAccession < LyberCore::Robot
        def initialize
          super('accessionWF', 'start-accession')
        end

        def perform_work
          raise 'Accessioning has been started with an object that is still open' if object_client.version.status.open?

          check_files! if cocina_object.dro?
        end

        private

        def check_files! # rubocop:disable Metrics/MethodLength
          # There may be a latency before staging files are visible in this mount, so we will retry a few times.
          retries = 0
          staging_present = nil
          begin
            staging_present = staging_pathname.exist?
            missing_files = audit_files

            raise "Files missing from staging, workspace, shelves, and preservation: #{missing_files.join(', ')}" if missing_files.present?
          rescue StandardError
            if !staging_present && retries < 3
              retries += 1
              sleep((Settings.sleep_coefficient * 5) * retries) # wait before retrying
              retry
            end
            raise
          end
        end

        # @return [Array<String>] list of files that are missing from staging, workspace, and preservation
        def audit_files
          cocina_files.filter_map do |file|
            next if found_or_skip?(file)

            file.filename
          end
        end

        def found_or_skip?(file) # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
          # Files that are dark (not published or shelved) are not accessioned.
          return true if !file.administrative.publish && !file.administrative.shelve
          # Every file should be in staging, workspace, shelf, or preservation.
          return true if check_file(dir_pathname: staging_pathname, file: file)
          return true if check_file(dir_pathname: workspace_pathname, file: file)

          # First version of a DRO isn't shelved or preserved yet.
          if cocina_object.version > 1
            md5 = file.hasMessageDigests.find { |message_digest| message_digest.type == 'md5' }.digest
            return true if check_preservation_file(file: file, md5: md5)
            return true if check_shelved_file(file: file, md5: md5)
          end
          false
        end

        def cocina_files
          cocina_object.structural.contains.flat_map do |fileset|
            fileset.structural.contains
          end
        end

        def staging_pathname
          @staging_pathname ||= DruidTools::Druid.new(druid, Settings.sdr.staging_root).pathname
        end

        def workspace_pathname
          @workspace_pathname ||= DruidTools::Druid.new(druid, Settings.sdr.local_workspace_root).pathname
        end

        def preservation_client
          @preservation_client ||= Preservation::Client.configure(url: Settings.preservation_catalog.url, token: Settings.preservation_catalog.token)
        end

        # @return [boolean] true if the file exists and has the expected size
        def check_file(dir_pathname:, file:)
          file_pathname = dir_pathname.join('content', file.filename)
          file_pathname.exist? && file_pathname.size == file.size
        end

        # @return [boolean] true if the file exists in preservation and has the expected MD5
        def check_preservation_file(file:, md5:)
          file.administrative.sdrPreserve && preservation_files_md5_map[file.filename] == md5
        end

        def preservation_files_md5_map
          @preservation_files_md5_map ||= preservation_client.objects.checksum(druid: druid).each_with_object({}) do |hash, map|
            map[hash[:filename]] = hash[:md5]
          end
        end

        # @return [boolean] true if the file exists on shelfs and has the expected MD5
        def check_shelved_file(file:, md5:)
          file.administrative.shelve && shelve_files_md5_map[file.filename] == md5
        end

        def shelve_files_md5_map
          @shelve_files_md5_map ||= begin
            PurlFetcher::Client::Reader.new(host: Settings.purl_fetcher.url).files_by_digest(druid).each_with_object({}) do |hash, map|
              map[hash.values.first] = hash.keys.first
            end
          rescue PurlFetcher::Client::NotFoundResponseError
            {}
          end
        end
      end
    end
  end
end
