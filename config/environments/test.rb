# frozen_string_literal: true

CERT_DIR = File.join(File.dirname(__FILE__), '../..', 'certs')

Dor::Config.configure do
  fedora do
    url Settings.fedora.url
  end

  solr.url Settings.solr.url
end

REDIS_URL = Settings.redis.url
