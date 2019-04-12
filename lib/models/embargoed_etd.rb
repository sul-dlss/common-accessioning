# frozen_string_literal: true

require 'etd_model'

class EmbargoedEtd < EtdModel::Etd
  RELEASE_ACCESS_XML = <<-EOXML
  <releaseAccess>
    <access type="read">
      <machine>
        <world/>
      </machine>
    </access>
  </releaseAccess>
  EOXML

  include Dor::Rightsable
  include Dor::Embargoable

  # Sets status, release date and release access for the embargoMetadata datastream.
  #   The caller should save the object and do any workflow updates
  # @param [String] release_dt_str month, date and year where embargo will be lifted
  # TODO move to dor-services gem afer Etds have been migrated
  def add_embargo(release_dt_str)
    ds = datastreams['embargoMetadata']

    ds.status = 'embargoed'
    ds.release_date = Time.parse(release_dt_str)
    ds.release_access_node = Nokogiri::XML(RELEASE_ACCESS_XML)
  end
end
