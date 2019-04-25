# frozen_string_literal: true

# Call Symphony and build the descMetadata datastream with what Symphony returns
class DescMetadataService
  def self.build(obj, datastream)
    content = fetch_datastream(obj)
    return if content.nil?

    datastream.dsLabel = 'Descriptive Metadata'
    datastream.ng_xml = Nokogiri::XML(content)
    datastream.ng_xml.normalize_text!
    datastream.content = datastream.ng_xml.to_xml
  end

  def self.fetch_datastream(obj)
    candidates = obj.identityMetadata.otherId.collect(&:to_s)
    metadata_id = Dor::MetadataService.resolvable(candidates).first
    metadata_id.nil? ? nil : Dor::MetadataService.fetch(metadata_id.to_s)
  end
  private_class_method :fetch_datastream
end
