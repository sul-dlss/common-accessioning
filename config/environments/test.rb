# frozen_string_literal: true

CERT_DIR = File.join(File.dirname(__FILE__), '../..', 'certs')

Dor::Config.configure do
  fedora do
    url Settings.fedora.url
  end

  solr.url Settings.solr.url
end

REDIS_URL = Settings.redis.url

# Remote location of ETD content
ETD_WORKSPACE = Settings.etd.workspace

# hostname where symphony resides
SYMPHONY_URL = Settings.symphony.url

# location where marc output will be dumped
MARC_OUTPUT_DIRECTORY = Settings.marc_output_directory
