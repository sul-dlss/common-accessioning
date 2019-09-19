# frozen_string_literal: true

CERT_DIR = File.join(File.dirname(__FILE__), '../..', 'certs')

Dor::Config.configure do
  fedora do
    url 'http://fedoraAdmin:fedoraAdmin@localhost:8983/fedora'
  end

  # ssl do
  #   cert_file File.join(CERT_DIR, 'dlss-dev-test.crt')
  #   key_file  File.join(CERT_DIR, 'dlss-dev-test.key')
  #   key_pass  ''
  # end

  workflow.url 'https://example.com/workflow/'
  solr.url 'http://localhost:8984/solr/argo'

  stacks do
    document_cache_host 'purl-test.stanford.edu'
    local_workspace_root '/dor/workspace'
    local_stacks_root '/stacks'
    local_document_cache_root '/purl/document_cache'
  end
end

REDIS_URL = '127.0.0.1:6379/resque:development' # hostname:port[:db]/namespace
# REDIS_TIMEOUT = '5' # seconds

# Remote location of ETD content
ETD_WORKSPACE = 'lyberadmin@lyberapps-dev.stanford.edu:/home/lyberadmin/workspace/'

# hostname where symphony resides
SYMPHONY_URL = 'http://lyberservices-dev.stanford.edu/cgi-bin/holdings.php?flexkey='

# location where marc output will be dumped
MARC_OUTPUT_DIRECTORY = '/tmp'
