# frozen_string_literal: true

CERT_DIR = File.join(File.dirname(__FILE__), '../..', 'certs')

Dor::Config.configure do
  fedora do
    url       'https://USERNAME:PASSWORD@example.com/fedora'
  end

  ssl do
    cert_file File.join(CERT_DIR, 'dlss-dev-test.crt')
    key_file  File.join(CERT_DIR, 'dlss-dev-test.key')
    key_pass  ''
  end

  workflow.url 'https://example.com/workflow/'
  solr.url 'http://localhost:8983/solr/argo'

  robots do
    workspace '/tmp'
  end

  metadata do
    catalog.url 'http://example.edu/catalog/mods'
    catalog.user 'user'
    catalog.pass 'pass'
  end

  assembly do
    root_dir      ['spec/test_input', 'spec/test_input2'] # directories to search for content that should be acted upon by the robots
    cm_file_name  'contentMetadata.xml' # the name of the contentMetadata file
    stub_cm_file_name 'stubContentMetadata.xml' # the name of the stub contentMetadata file
    dm_file_name  'descMetadata.xml' # the name of the descMetadata file
    next_workflow 'accessionWF' # name of the next workflow to start after assembly robots are done
    overwrite_jp2     false # indicates if the jp2-create robot should overwrite an existing jp2 of the same name as the new one being created
    overwrite_dpg_jp2 false # indicates if the jp2-create robot should create a jp2 when there is a corresponding DPG style jp2
    # (e.g. oo000oo0001_00_001.tif and oo000oo0001_05_001.jp2, then a "false" setting here would NOT generate a new jp2 even though there is no filename clash)
    robot_sleep_time 30 # how long robots will sleep before attemping to connect to workflow service again
    tmp_folder '/tmp' # tmp file location for jp2-create and imagemagick
  end

  release do
    fetcher_root 'http://localhost:3000/'
    workflow_name 'releaseWF'
    max_tries 1 # the number of attempts to retry service calls before failing
    max_sleep_seconds 1  # max sleep seconds between tries
    base_sleep_seconds 1 # base sleep seconds between tries
  end

  stacks do
    document_cache_storage_root '/purl/document_cache'
    document_cache_host 'purl-test.stanford.edu'
    local_workspace_root '/dor/workspace'
    local_stacks_root '/stacks'
    local_document_cache_root '/purl/document_cache'
    local_recent_changes '/purl/recent_changes'
    url 'https://stacks-test.stanford.edu'
    iiif_profile 'http://iiif.io/api/image/2/level1.json'
  end

  dor_services do
    url  'https://example.com'
    user 'USERNAME'
    pass 'PASSWORD'
  end
  purl_services.url 'https://example.com'
end

REDIS_URL = '127.0.0.1:6379/resque:development' # hostname:port[:db]/namespace
# REDIS_TIMEOUT = '5' # seconds
