# frozen_string_literal: true

module Dor
  # builds the FileSet instance from a Dor::Item
  class FileSets
    # @param [Nokogir::XML::Document] ng_xml
    # @param [Integer] version
    # @param [Cocina::Models::DROAccess] access to copy down to the files
    def self.build(ng_xml:, version:, dro_access:)
      new(
        ng_xml,
        version: version,
        dro_access: dro_access
      ).build
    end

    def initialize(ng_xml, version:, dro_access:)
      @ng_xml = ng_xml
      @version = version
      @dro_access = dro_access
    end

    def build
      ng_xml.xpath('//resource[file]').map do |resource_node|
        files = build_files(resource_node.xpath('file'))
        structural = {}
        structural[:contains] = files if files.present?
        {
          externalIdentifier: resource_node['id'],
          type: resource_type(resource_node),
          version: version,
          structural: structural
        }.tap do |attrs|
          attrs[:label] = resource_node.xpath('label', 'attr[@type="label"]', 'attr[@name="label"]').text # some will be missing labels, they will just be blank
        end
      end
    end

    private

    attr_reader :ng_xml, :version, :dro_access

    def resource_type(resource_node)
      val = resource_node['type']&.underscore
      val = 'three_dimensional' if val == '3d'
      return Cocina::Models::Vocab::Resources.public_send(val) if val && Cocina::Models::Vocab::Resources.respond_to?(val)

      raise "Invalid resource type: '#{val}'"
    end

    def digests(node)
      [].tap do |digests|
        # Web archive crawls use SHA1/MD5
        sha1 = node.xpath('checksum[@type="sha1" or @type="SHA1"]').text.presence
        digests << { type: 'sha1', digest: sha1 } if sha1
        md5 = node.xpath('checksum[@type="md5" or @type="MD5"]').text.presence
        digests << { type: 'md5', digest: md5 } if md5
      end
    end

    def build_files(file_nodes)
      file_nodes.map do |node|
        height = node.xpath('imageData/@height').text.presence&.to_i
        width = node.xpath('imageData/@width').text.presence&.to_i
        use = node.xpath('@role').text.presence
        {
          # External identifier is always generated because it is not stored in Fedora.
          externalIdentifier: "http://cocina.sul.stanford.edu/file/#{SecureRandom.uuid}",
          type: Cocina::Models::Vocab.file,
          label: node['id'],
          filename: node['id'],
          size: node['size'].to_i,
          version: version,
          hasMessageDigests: digests(node),
          access: file_access,
          administrative: {
            publish: node['publish'] == 'yes',
            sdrPreserve: node['preserve'] == 'yes',
            shelve: node['shelve'] == 'yes'
          }
        }.tap do |attrs|
          # Files from Goobi don't have mimetype until they hit exif-collect in the assemblyWF
          attrs[:hasMimeType] = node['mimetype'] if node['mimetype'].present?
          attrs[:presentation] = { height: height, width: width } if height && width
          attrs[:use] = use if use
        end
      end
    end

    def file_access
      file_access = dro_access.to_h.slice(:access, :download, :readLocation, :controlledDigitalLending)
      file_access[:access] = 'dark' if file_access[:access] == 'citation-only'
      file_access
    end
  end
end
