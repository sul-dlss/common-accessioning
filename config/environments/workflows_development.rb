#
# List the robots that you want to run, using fully-qualified robot name.
# For example, dor:accessionWF:technical-metadata
#
# To listen only to a specific priority, append the robot with :priority. 
# For example: dor:accessionWF:technical-metadata:high
#
# To start multiple robots of the same kind, simply list the robot
# multiple times.
#
WORKFLOW_STEPS = case `hostname -s`.rstrip
when 'sul-robots1-dev'
  %w{
    dor:accessionWF:start-accession
    dor:accessionWF:descriptive-metadata
    dor:accessionWF:rights-metadata
    dor:accessionWF:content-metadata
    dor:accessionWF:technical-metadata
    dor:accessionWF:technical-metadata
    dor:accessionWF:technical-metadata:critical
    dor:accessionWF:technical-metadata:high
    dor:accessionWF:remediate-object
    dor:accessionWF:shelve
    dor:accessionWF:shelve
    dor:accessionWF:shelve
    dor:accessionWF:publish
    dor:accessionWF:provenance-metadata
    dor:accessionWF:sdr-ingest-transfer
    dor:accessionWF:end-accession
    dor:disseminationWF:cleanup
  }
when 'sul-robots2-dev', 'sul-lyberservices-dev'
  %w{
    dor:accessionWF:start-accession
    dor:accessionWF:descriptive-metadata
    dor:accessionWF:rights-metadata
    dor:accessionWF:content-metadata
    dor:accessionWF:technical-metadata
    dor:accessionWF:remediate-object
    dor:accessionWF:shelve
    dor:accessionWF:publish
    dor:accessionWF:provenance-metadata
    dor:accessionWF:sdr-ingest-transfer
    dor:accessionWF:end-accession
    dor:disseminationWF:cleanup
  }
else
  raise ArgumentError, "Unknown host"
end
