# frozen_string_literal: true

# Builds the list of URIs for files in an object
class FileUris
  # @param [String] druid
  # @param [Cocina::Models::DRO]
  def self.build(druid, obj)
    filenames = extract_filenames(obj)

    workspace = DruidTools::Druid.new(druid, File.absolute_path(Settings.sdr.local_workspace_root))
    content_dir = workspace.find_filelist_parent('content', filenames)

    filenames.map do |filename|
      URI::File.build(path: File.join(content_dir, filename).gsub(' ', '%20')).to_s
    end
  end

  def self.extract_filenames(obj)
    filenames = []
    obj.structural.contains.each do |fileset|
      next if fileset.structural.contains.blank?

      fileset.structural.contains.each do |file|
        filenames << file.label
      end
    end
    filenames
  end
  private_class_method :extract_filenames
end
