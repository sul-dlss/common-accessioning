# will spawn worker(s) for each of the given workflows (fully qualified as "repo:wf:robot")
WORKFLOW_STEPS = %w{
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

# number of workers for the given workflows
# by default, 1 is started per item in WORKFLOW_STEPS
WORKFLOW_N = Hash[*%w{
  dor:accessionWF:technical-metadata     3
}]
