#!/usr/bin/env ruby
#
# Finds objects where the embargo release date has passed for embargoed items
# Builds list of candidate objects by doing a Solr query
#
# Should run once a day from cron
# Example cron entry
# 16 2 * * * bash --login -c 'cd /home/lyberadmin/common-accessioning && ROBOT_ENVIRONMENT=test ruby ./robots/accession/embargo_release.rb' > /home/lyberadmin/common-accessioning/log/crondebug.log 2>&1

require File.expand_path(File.dirname(__FILE__) + '/../../config/boot')

# Turn off active_fedora updates of solr
ENABLE_SOLR_UPDATES = false
LyberCore::Log.set_logfile(File.join(ROBOT_ROOT, "log", "embargo_release.log"))

# Finds druids from solr based on the passed in query
# It will then load each item from Dor, and call the block with the item
# @param [String] query used to locate druids of items to release from solr
# @param [String] embargo_msg embargo type used in log messages (embargo vs 20% visibilty embargo)
# @param [Proc] release_bloc gets executed after loading the object from DOR and opening new version
#  Steps needed to release the particular embargo from the item
def release_items(query, embargo_msg="embargo", &release_block)
  # Find objects to process
  LyberCore::Log.info("***** Querying solr: " << query)
  solr = Dor::SearchService.query(query, "rows" => "5000", "fl" => "id")

  num_found = solr["response"]["numFound"]
  if(num_found == 0)
    LyberCore::Log.info("No objects to process")
    return
  end
  LyberCore::Log.info("Found #{num_found} objects")

  druid = ''
  count = 0
  solr["response"]["docs"].each do |doc|
    begin
      druid = doc["id"].first
      LyberCore::Log.info("Releasing #{embargo_msg} for #{druid}")
      ei = Dor::Item.find(druid)
      ei.open_new_version
      release_block.call(ei)
      ei.save
      ei.close_version :description => "#{embargo_msg} released", :significance => :admin
      count += 1
    rescue Exception => e
      msg = "!!! Unable to release embargo for: #{druid}\n" << e.inspect << "\n" << e.backtrace.join("\n")
      LyberCore::Log.error(msg)
      Dor::WorkflowService.update_workflow_error_status 'dor', druid, 'accessionWF', 'embargo-release', "#{e.to_s}"
    end
  end

  LyberCore::Log.info("Done! Processed #{count} objects out of #{num_found}")
end

def release
  release_items("embargoMetadata_status_facet:'embargoed' AND embargo_release_date_dt:[* TO NOW]") do |item|
    item.release_embargo("application:accessionWF:embargo-release")
  end

  release_items("embargoMetadata_twenty_pct_status_facet:'embargoed' AND twenty_pct_visibility_release_date_dt:[* TO NOW]",
                "20% visibility embargo") do |item|
    item.release_embargo("application:accessionWF:embargo-release")
  end
end

release
