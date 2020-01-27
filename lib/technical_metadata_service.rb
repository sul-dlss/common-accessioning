# frozen_string_literal: true

require 'moab/stanford'
require 'jhove_service'

# Extracts technical metadata from files using JHOVE
# If this is a new version it gets the old technicalMetadata datastream by
# making an API call to preservation-catalog (via preservation-client) and
# only overwrites/adds parts for the files that were changed or added.
# This allows us to avoid re-staging files that have not changed.
# Switching to a more granular data model that has file metadata separate from
# the Work metadata will allow us to simplify this greatly.
class TechnicalMetadataService
  # @param [Dor::Item] dor_item The DOR item being processed by the technical metadata robot
  # @return [Boolean] True if technical metadata is correctly added or updated
  def self.add_update_technical_metadata(dor_item)
    new(dor_item).add_update_technical_metadata
  end

  def initialize(dor_item)
    @dor_item = dor_item
  end

  def add_update_technical_metadata
    # This is an experiment to determine whether files are always staged when updating tech md. It will be removed.
    check_all_files_staged

    diff = content_group_diff
    deltas = diff.file_deltas
    old_techmd = old_technical_metadata
    new_techmd = new_technical_metadata(deltas)
    # this is version 1 or previous technical metadata was not saved
    return store(new_techmd) if old_techmd.nil?

    return true if diff.difference_count.zero?

    merged_nodes = merge_file_nodes(old_techmd, new_techmd, deltas)
    final_techmd = build_technical_metadata(merged_nodes)
    store(final_techmd)
  end

  private

  attr_reader :dor_item

  def check_all_files_staged
    content_metadata = dor_item.contentMetadata
    return unless content_metadata

    ng_doc = Nokogiri::XML(content_metadata.content)
    files = ng_doc.xpath('//file/@id').map(&:content)
    workspace = DruidTools::Druid.new(dor_item.pid, Settings.sdr.local_workspace_root)

    content_dir = workspace.content_dir(false)
    return unless Dir.exist?(content_dir) && !Dir.empty?(content_dir)

    # This will raise an error if any of the files are missing.
    begin
      workspace.find_filelist_parent('content', files)
    rescue StandardError => e
      Honeybadger.notify("Not all files staged for #{dor_item.pid} when extracting tech md: #{e}. This is part of an " \
        'experiment.')
    end
  end

  def store(final_techmd)
    ds = dor_item.datastreams['technicalMetadata']
    ds.dsLabel = 'Technical Metadata'
    ds.content = final_techmd
    # NOTE: can't use save! because this is an ActiveFedora::Datastream, so we get
    # OM::XML::Terminology::BadPointerError:
    #   This Terminology does not have a root term defined that corresponds to ":save!"
    raise "problem saving ActiveFedora::Datastream technicalMetadata for #{dor_item.pid}" unless ds.save

    true
  end

  # @return [FileGroupDifference] The differences between two versions of a group of files
  def content_group_diff
    return Moab::FileGroupDifference.new if dor_item.contentMetadata.nil?
    raise Dor::ParameterError, 'Missing Dor::Config.stacks.local_workspace_root' if Dor::Config.stacks.local_workspace_root.nil?

    current_content = dor_item.contentMetadata.content
    inventory_diff = Preservation::Client.objects.content_inventory_diff(druid: dor_item.pid, content_metadata: current_content)
    inventory_diff.group_difference('content')
  end

  # @param [Hash<Symbol,Array>] deltas Sets of filenames grouped by change type for use in performing file or metadata operations
  # @return [Array<String>] The list of filenames for files that are either added or modifed since the previous version
  def new_files(deltas)
    deltas[:added] + deltas[:modified]
  end

  # @return [String] The technicalMetadata datastream from the previous version of the digital object
  def old_technical_metadata
    pres_techmd = preservation_technical_metadata
    return pres_techmd unless pres_techmd.nil?

    dor_technical_metadata
  end

  # @return [String] The technicalMetadata datastream from the previous version of the digital object (fetched from preservation)
  #   The data is updated to the latest format.
  def preservation_technical_metadata
    pres_techmd = preservation_metadata('technicalMetadata')
    return pres_techmd if pres_techmd =~ /<technicalMetadata/
    return ::JhoveService.new.upgrade_technical_metadata(pres_techmd) if pres_techmd =~ /<jhove/

    nil
  end

  # @return [String] The technicalMetadata datastream from the previous version of the digital object (fetched from DOR fedora).
  #   The data is updated to the latest format.
  def dor_technical_metadata
    ds = 'technicalMetadata'
    return nil unless dor_item.datastreams.key?(ds) && !dor_item.datastreams[ds].new?

    dor_techmd = dor_item.datastreams[ds].content
    return dor_techmd if dor_techmd =~ /<technicalMetadata/
    return ::JhoveService.new.upgrade_technical_metadata(dor_techmd) if dor_techmd =~ /<jhove/

    nil
  end

  # @param [String] dsname The identifier of the metadata datastream
  # @return [String] The datastream contents from the previous version of the digital object (fetched from preservation),
  #   or nil if there is no such datastream (e.g. object not yet in preservation)
  def preservation_metadata(dsname)
    Preservation::Client.objects.metadata(druid: dor_item.pid, filepath: "#{dsname}.xml")
  rescue Preservation::Client::NotFoundError
    nil
  end

  # @param [Hash<Symbol,Array>] deltas Sets of filenames grouped by change type for use in performing file or metadata operations
  # @return [String] The technicalMetadata datastream for the new files of the new digital object version
  def new_technical_metadata(deltas)
    new_files = new_files(deltas)

    return nil if new_files.nil? || new_files.empty?

    workspace = DruidTools::Druid.new(dor_item.pid, Settings.sdr.local_workspace_root)
    content_dir = workspace.find_filelist_parent('content', new_files)
    temp_dir = workspace.temp_dir
    jhove_service = ::JhoveService.new(temp_dir)
    jhove_service.digital_object_id = dor_item.pid
    fileset_file = write_fileset(temp_dir, new_files)
    jhove_output_file = jhove_service.run_jhove(content_dir, fileset_file)
    tech_md_file = jhove_service.create_technical_metadata(jhove_output_file)
    IO.read(tech_md_file)
  end

  # @param [Pathname]  temp_dir  The pathname of the temp folder in the object's workspace area
  # @param [Object] new_files [Array<String>] The list of filenames for files that are either added or modifed since the previous version
  # @return [Pathname] Save the new_files list to a text file and return that file's name
  def write_fileset(temp_dir, new_files)
    fileset_pathname = Pathname(temp_dir).join('jhove_fileset.txt')
    fileset_pathname.open('w') { |f| f.puts(new_files) }
    fileset_pathname
  end

  # @param [String] old_techmd The technicalMetadata datastream from the previous version of the digital object
  # @param [String] new_techmd The technicalMetadata datastream for the new files of the new digital object version
  # @param [Array<String>] deltas The list of filenames for files that are either added or modifed since the previous version
  # @return [Hash<String,Nokogiri::XML::Node>] The complete set of technicalMetadata nodes for the digital object, indexed by filename
  def merge_file_nodes(old_techmd, new_techmd, deltas)
    old_file_nodes = file_nodes(old_techmd)
    new_file_nodes = file_nodes(new_techmd)
    merged_nodes = {}
    # Note that this handles the error case when the old techmd does not include some files it is expected to.
    deltas[:identical].each do |path|
      next unless old_file_nodes.key?(path)

      merged_nodes[path] = old_file_nodes[path]
    end
    deltas[:modified].each do |path|
      merged_nodes[path] = new_file_nodes[path]
    end
    deltas[:added].each do |path|
      merged_nodes[path] = new_file_nodes[path]
    end
    deltas[:renamed].each do |oldpath, newpath|
      next unless old_file_nodes.key?(oldpath)

      clone = old_file_nodes[oldpath].clone
      clone.sub!(/<file\s*id.*?["'].*?["'].*?>/, "<file id='#{newpath}'>")
      merged_nodes[newpath] = clone
    end
    deltas[:copyadded].each do |oldpath, newpath|
      next unless old_file_nodes.key?(oldpath)

      clone = old_file_nodes[oldpath].clone
      clone.sub!(/<file\s*id.*?["'].*?["'].*?>/, "<file id='#{newpath}'>")
      merged_nodes[newpath] = clone
    end
    merged_nodes
  end

  # @param [String] technical_metadata A technicalMetadata datastream contents
  # @return [Hash<String,Nokogiri::XML::Node>] The set of nodes from a technicalMetadata datastream, indexed by filename
  def file_nodes(technical_metadata)
    file_hash = {}
    return file_hash if technical_metadata.nil?

    current_file = []
    path = nil
    in_file = false
    technical_metadata.each_line do |line|
      if line =~ /^\s*<file.*["'](.*?)["']/
        current_file << line
        path = Regexp.last_match(1)
        in_file = true
      elsif line =~ %r{^\s*</file>}
        current_file << line
        file_hash[path] = current_file.join
        current_file = []
        path = nil
        in_file = false
      elsif in_file
        current_file << line
      end
    end
    file_hash
  end

  # @param [Hash<String,Nokogiri::XML::Node>] merged_nodes The complete set of technicalMetadata nodes for the digital object, indexed by filename
  # @return [String] The finalized technicalMetadata datastream contents for the new object version
  def build_technical_metadata(merged_nodes)
    techmd_root = +<<~EOF
      <technicalMetadata objectId='#{dor_item.pid}' datetime='#{Time.now.utc.iso8601}'
          xmlns:jhove='http://hul.harvard.edu/ois/xml/ns/jhove'
          xmlns:mix='http://www.loc.gov/mix/v10'
          xmlns:textmd='info:lc/xmlns/textMD-v3'>
    EOF
    doc = techmd_root
    merged_nodes.keys.sort.each { |path| doc << merged_nodes[path] }
    doc + '</technicalMetadata>'
  end
end
