# frozen_string_literal: true

Dor::Config.configure do
  fedora do
    url Settings.fedora.url
  end

  ssl do
    cert_file Settings.ssl.cert_file
    key_file Settings.ssl.key_file
    key_pass Settings.ssl.key_pass
  end

  suri do
    mint_ids Settings.suri.mint_ids
    id_namespace Settings.suri.id_namespace
    url Settings.suri.url
    user Settings.suri.user
    pass Settings.suri.pass
  end

  # Used by Dor::DigitalStacksService, Dor::PublishMetadataService, and Dor::ShelvingService
  stacks do
    document_cache_host Settings.stacks.document_cache_host
    local_workspace_root Settings.stacks.local_workspace_root
    local_stacks_root Settings.stacks.local_stacks_root
  end

  solr.url Settings.solr.url

  workflow do
    url Settings.workflow.url
    logfile Settings.workflow.logfile
    shift_age Settings.workflow.shift_age
  end
end

# External application locations
JHOVE_HOME = File.join(ENV['HOME'], 'jhoveToolkit')

REDIS_URL = Settings.redis.url

# Remote location of ETD content
ETD_WORKSPACE = Settings.etd.workspace

# hostname where symphony resides
SYMPHONY_URL = Settings.symphony.url

# location where marc output will be dumped
MARC_OUTPUT_DIRECTORY = Settings.marc_output_directory

# hostname, location, and credentials of the binder dropbox location
BINDER_DROPBOX_HOST = Settings.binder_dropbox.host
BINDER_DROPBOX_USER = Settings.binder_dropbox.user
BINDER_DROPBOX_STORAGE_ROOT = Settings.binder_dropbox.storage_root
