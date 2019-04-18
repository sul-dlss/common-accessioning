# frozen_string_literal: true

require 'etd_model'
require 'models/etd_metadata'

class Etd < EtdModel::Etd
  include EtdMetadata
end
