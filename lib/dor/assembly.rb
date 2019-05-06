# frozen_string_literal: true

require 'assembly-image'

module Dor
  module Assembly
  end
end
Dor::Config.configure do
  assembly do
    jp2_resource_types  %w[page image] # only file nodes in resources of this 'type' will have jp2 derivatives made, and only if valid image mimetypes as defined by assembly-objectfile gem
    items_only          true           # exif-collect, checksum-compute and jp2aable only operate on dor type="item" if this is set to true
    cm_file_name 'contentMetadata.xml' # the name of the contentMetadata file
    stub_cm_file_name 'stubContentMetadata.xml' # the name of the stub contentMetadata file
    dm_file_name 'descMetadata.xml' # the name of the descMetadata file
  end
end
