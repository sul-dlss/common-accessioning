#!/usr/bin/env ruby
#
# Finds objects where the embargo release date has passed for embargoed items
# Builds list of candidate objects by doing a Solr query from gsearch
#
# Should run once a day from cron
# Example cron entry
# 16 2 * * * bash --login -c 'cd /home/lyberadmin/common-accessioning && ROBOT_ENVIRONMENT=test ruby ./robots/accession/embargo_release.rb' > /home/lyberadmin/common-accessioning/log/crondebug.log 2>&1

require File.expand_path(File.dirname(__FILE__) + '/../../config/boot')
require 'dor/embargo'

class EmbargoedItem < Dor::Item
  include Dor::Embargo
  
  has_metadata :name => "embargoMetadata", :type => EmbargoMetadataDS, :label => 'Embargo Metadata'
  has_metadata :name => "events", :type => EventsDS, :label => 'Event History'
end

LyberCore::Log.set_logfile(File.join(ROBOT_ROOT, "log", "embargo_release.log"))

# Find objects to process
solr = Dor::SearchService.gsearch("q" => "embargo_status_field:'embargoed' AND embargo_release_date:[* TO NOW]", 
                                  "rows" => "5000", 
                                  "fl" => "id")

#r["response"]["docs"][0]["id"]
num_found = solr["response"]["numFound"]
if(num_found == 0)
  LyberCore::Log.info("No objects to process")
  exit
end

druid = ''
count = 0
solr["response"]["docs"].each do |doc|
  begin
    druid = doc["id"]
    LyberCore::Log.info("Releasing embargo for #{druid}")
    ei = EmbargoedItem.load_instance(druid)
    ei.release_embargo("application:accessionWF:embargo-release")
    ei.save
    Dor::WorkflowService.update_workflow_status 'dor', druid, 'accessionWF', 'embargo-release', 'completed'
    count += 1
  rescue Exception => e
    msg = "!!! Unable to release embargo for: #{druid}\n" << e.inspect << "\n" << e.backtrace.join("\n")
    LyberCore::Log.error(msg)
    Dor::WorkflowService.update_workflow_error_status 'dor', druid, 'accessionWF', 'embargo-release', "#{e.to_s}"
  end
end

LyberCore::Log.info("Done! Processed #{count} objects out of #{num_found}")
