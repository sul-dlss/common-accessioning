# frozen_string_literal: true

# Builds the list of URIs for the preserved files in an object
class PreservedFileUris
  UriMd5 = Struct.new('UriMd5', :uri, :md5)
  FilenameUri = Struct.new('FilenameUri', :filename, :uri)
  FilepathUri = Struct.new('FilepathUri', :filepath, :uri)

  # @param [String] druid
  # @param [Cocina::Models::DRO]
  def initialize(druid, obj)
    @obj = obj
    @druid = druid
  end

  # @return [Array<UriMd5>]
  def uris
    @uris ||= filepath_uris.map { |filepath_uri| UriMd5.new(FileUri.new(filepath_uri.filepath).to_s, filepath_uri.uri) }
  end

  def filepaths
    @filepaths ||= filepath_uris.map(&:filepath)
  end

  def content_dir
    @content_dir ||= DruidTools::Druid.new(druid, local_workspace_root).content_dir(false)
  end

  private

  attr_reader :obj, :druid

  def local_workspace_root
    @local_workspace_root ||= File.absolute_path(Settings.sdr.local_workspace_root)
  end

  def filepath_uris
    @filepath_uris ||= filename_uris.map { |filename_uri| FilepathUri.new(File.join(content_dir, filename_uri.filename), filename_uri.uri) }
  end

  def filename_uris
    @filename_uris ||= obj.structural.contains.flat_map do |fileset|
      preserved_filenames(fileset)
    end
  end

  def preserved_filenames(fileset)
    contains = fileset.structural.contains
    return [] if contains.blank?

    contains.filter { |file| file.administrative.sdrPreserve }.map { |file| filename_uri_for(file) }
  end

  def filename_uri_for(file)
    md5 = file.hasMessageDigests.find { |md| md.type == 'md5' }&.digest || ''
    FilenameUri.new(file.filename, md5)
  end
end
