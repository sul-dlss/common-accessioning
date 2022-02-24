# frozen_string_literal: true

module Dor
  # builds the Structural subschema for Cocina::Models::DRO from a Dor::Item
  class StructuralMetadata
    # @params [String] xml the contents of contentMetadata.xml
    # @params [Cocina::Models::DRO] cocina_item the item to update
    def self.update(xml, cocina_item)
      new(xml, cocina_item).update
    end

    def initialize(xml, cocina_item)
      @ng_xml = Nokogiri::XML(xml)
      @cocina_item = cocina_item
    end

    def update
      value = (cocina_item.structural || Cocina::Models::DROStructural).new(props)
      overwrite_dark_access(value)
    end

    # This detects and fixes a potential problem where they've provided files marked publish="yes" when access is "dark"
    def overwrite_dark_access(original)
      return original unless @cocina_item.access.access == 'dark'

      filtered_contained = original.contains.map do |file_set|
        filtered_files = file_set.structural.contains.map do |file|
          file.new(administrative: file.administrative.new(publish: false, shelve: false, sdrPreserve: true))
        end
        updated_structural = file_set.structural.new(contains: filtered_files)
        file_set.new(structural: updated_structural)
      end
      original.new(contains: filtered_contained)
    end

    def props
      {}.tap do |structural|
        has_member_orders = build_has_member_orders
        structural[:hasMemberOrders] = has_member_orders if has_member_orders.present?
        structural[:contains] = FileSets.build(ng_xml: ng_xml, version: version, dro_access: cocina_item.access)
      end
    end

    private

    attr_reader :ng_xml, :cocina_item

    delegate :version, to: :cocina_item

    def type
      ng_xml.xpath('//contentMetadata').first.attribute('type').value
    end

    def build_has_member_orders
      member_orders = create_member_order if type == 'book'
      sequence = build_sequence
      if sequence.present?
        member_orders ||= [{}]
        member_orders.first[:members] = sequence
      end
      member_orders
    end

    def create_member_order
      reading_direction = ng_xml.xpath('//bookData/@readingOrder').first&.value
      viewing_direction = ViewingDirectionHelper.viewing_direction(reading_direction)
      viewing_direction ||= 'left-to-right'

      [{ viewingDirection: viewing_direction }]
    end

    # @return [Array<String>] the identifiers of files in a sequence for a virtual object
    def build_sequence
      ng_xml.xpath('//resource/externalFile').map do |resource_node|
        resource_node['objectId']
      end
    end
  end
end
