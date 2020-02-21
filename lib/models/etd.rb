# frozen_string_literal: true

class Etd < Dor::Etd
  # @param [String] druid the identifier of the object
  # @return [Etd] the object from Fedora
  def self.find(druid)
    # We have to do 'cast: false' or this will become a Dor::Item (due to the identityMetadata.objectType)
    # See Dor::Abstract#adapt_to_cmodel
    super(druid, cast: false)
  end
end
