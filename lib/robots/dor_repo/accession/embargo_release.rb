# frozen_string_literal: true

require File.expand_path(File.dirname(__FILE__) + '/../../../../config/boot')

# !/usr/bin/env ruby
#
# Finds objects where the embargo release date has passed for embargoed items
# Builds list of candidate objects by doing a Solr query
#
# Should run once a day from cron
# Example cron entry
# 16 2 * * * bash --login -c 'cd /home/lyberadmin/common-accessioning && ROBOT_ENVIRONMENT=test ruby ./robots/accession/embargo_release.rb' > /home/lyberadmin/common-accessioning/log/crondebug.log 2>&1

module Robots
  module DorRepo
    module Accession
      class EmbargoRelease
        # Turn off active_fedora updates of solr
        ENABLE_SOLR_UPDATES = false
        LyberCore::Log.set_logfile(File.join(ROBOT_ROOT, 'log', 'embargo_release.log'))
        # Finds druids from solr based on the passed in query
        # It will then load each item from Dor, and call the block with the item
        # @param [String] query used to locate druids of items to release from solr
        # @param [String] embargo_msg embargo type used in log messages (embargo vs 20% visibilty embargo)
        # @yield [Dor::Item] gets executed after loading the object from DOR and opening new version
        #  Steps needed to release the particular embargo from the item
        def self.release_items(query, embargo_msg = 'embargo', &release_block)
          # Find objects to process
          LyberCore::Log.info("***** Querying solr: #{query}")
          solr = Dor::SearchService.query(query, 'rows' => '5000', 'fl' => 'id')

          num_found = solr['response']['numFound']
          if num_found == 0
            LyberCore::Log.info('No objects to process')
            return
          end
          LyberCore::Log.info("Found #{num_found} objects")

          count = 0
          solr['response']['docs'].each do |doc|
            release_item(doc['id'], embargo_msg, &release_block)
            count += 1
          end

          LyberCore::Log.info("Done! Processed #{count} objects out of #{num_found}")
        end

        def self.release_item(druid, embargo_msg, &release_block)
          ei = Dor.find(druid)

          unless Dor::Config.workflow.client.lifecycle('dor', druid, 'accessioned')
            LyberCore::Log.warn("Skipping #{druid} - not yet accessioned")
            return
          end

          LyberCore::Log.info("Releasing #{embargo_msg} for #{druid}")

          dor_service = Dor::Services::Client.object(druid)
          dor_service.version.open
          release_block.call(ei)
          ei.save!
          dor_service.version.close(description: "#{embargo_msg} released", significance: 'admin')
        rescue Exception => e
          LyberCore::Log.error("!!! Unable to release embargo for: #{druid}\n#{e.inspect}\n#{e.backtrace.join("\n")}")
          Honeybadger.notify "Unable to release embargo for: #{druid}", backtrace: e.backtrace
        end
        private_class_method :release_item

        def self.release
          release_items('embargo_status_ssim:"embargoed" AND embargo_release_dtsim:[* TO NOW]') do |item|
            item.release_embargo('application:accessionWF:embargo-release')
          end

          release_items('twenty_pct_status_ssim:"embargoed" AND twenty_pct_visibility_release_dtsim:[* TO NOW]',
                        '20% visibility embargo') do |item|
            item.release_20_pct_vis_embargo('application:accessionWF:embargo-release')
          end
        end
      end
    end
  end
end

Robots::DorRepo::Accession::EmbargoRelease.release
