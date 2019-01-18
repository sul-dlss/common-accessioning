# frozen_string_literal: true

# methods to help parse the stub content metadata file
module StubContentMetadataParser
  # this maps types coming from the stub content metadata (e.g. as produced by goobi) into the contentMetadata types allowed by the Assembly::Objectfile gem for CM generation
  def gem_content_metadata_style
    if stub_object_type.include?('book')
      :simple_book
    elsif stub_object_type.include?('map')
      :map
    elsif stub_object_type == 'image'
      :simple_image
    else
      :file # the default content metadata style if not found via the mapping is :file
    end
  end

  def stub_object_type
    node = @stub_cm.xpath('/content/@type')
    node.empty? ? nil : node.first.value.downcase.strip
  end

  def resources
    @stub_cm.xpath('//resource')
  end

  def resource_label(resource)
    node = resource.css('/label')
    node.empty? ? '' : node.first.content
  end

  def resource_files(resource)
    resource.css('/file')
  end

  def filename(file)
    file.at_xpath('@name').value
  end

  # return a hash for any known file attributes defined in the stub content metadata file, these will override or add to the defaults
  def stub_file_attributes(file)
    result = {}
    %w[preserve publish shelve role].each { |attribute| result[attribute.to_sym] = file.at_xpath("@#{attribute}").value unless file.at_xpath("@#{attribute}").blank? }
    result
  end
end
