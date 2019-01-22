# frozen_string_literal: true

require 'etd_model'
require 'etd_metadata'

class Etd < EtdModel::Etd
  include EtdMetadata
end
