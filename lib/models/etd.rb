# frozen_string_literal: true

require 'models/etd_metadata'

class Etd < Dor::Etd
  include EtdMetadata
end
