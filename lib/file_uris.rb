# frozen_string_literal: true

# Builds the list of URIs for files in an object
class FileUris
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
    @uris ||= filepaths.map { |filepath| URI::File.build(path: filepath.gsub(' ', '%20')).to_s }
  end

  private

  attr_reader :obj, :druid

  def content_dir
    workspace = DruidTools::Druid.new(druid, File.absolute_path(Settings.sdr.local_workspace_root))
    workspace.content_dir(false)
  end

  def filenames
    @filenames ||= begin
      filenames = []
      obj.structural.contains.each do |fileset|
        next if fileset.structural.contains.blank?

        fileset.structural.contains.each do |file|
          filenames << file.label
        end
      end
      filenames
    end
  end
end
