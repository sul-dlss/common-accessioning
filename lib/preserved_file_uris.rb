# frozen_string_literal: true

# Builds the list of URIs for the preserved files in an object
class PreservedFileUris
  # @param [String] druid
  # @param [Cocina::Models::DRO]
  def initialize(druid, obj)
    @obj = obj
    @druid = druid
  end

  def filepaths
    @filepaths ||= filenames.map { |filename| File.join(content_dir, filename) }
  end

  def uris
    @uris ||= filepaths.map { |filepath| FileUri.new(filepath).to_s }
  end

  private

  attr_reader :obj, :druid

  def content_dir
    workspace = DruidTools::Druid.new(druid, File.absolute_path(Settings.sdr.local_workspace_root))
    workspace.content_dir(false)
  end

  def filenames
    @filenames ||= obj.structural.contains.flat_map do |fileset|
      preserved_filenames(fileset)
    end
  end

  def preserved_filenames(fileset)
    contains = fileset.structural.contains
    return [] if contains.blank?

    contains.filter { |file| file.administrative.sdrPreserve }.map(&:label)
  end
end
