# frozen_string_literal: true

# Add checksums to all files listed in contentMetadata
# Compare with SDRs checksums and log any differences

def fix_xsums(druid)
  i = Dor.find druid
  cmds = i.contentMetadata
  files = cmds.resource.file.id

  dt = DruidTools::Druid.new(i.pid, Dor::Config.stacks.local_workspace_root)
  sdr_cm_doc = get_sdr_cm(druid)
  files.each do |fname|
    path = dt.path(fname).gsub('/' + i.pid.gsub('druid:', ''), '')
    unless (File.exists?(path))
      LOG.warn "Skipping #{fname} for #{druid}: it does not exist in the workspace"
      next
    end
    md5 = Digest::MD5.file(path).hexdigest
    sha1 = Digest::SHA1.file(path).hexdigest
    size = File.size?(path)
    #update contentmd
    file_hash = {:name => fname, :md5 => md5, :size => size.to_s, :sha1 => sha1}
    cmds.update_file file_hash, fname
    compare_checksums_with_sdr(druid, file_hash, sdr_cm_doc) if (sdr_cm_doc)
  end
  cmds.save

end

def get_sdr_cm(druid)
  doc = nil
  begin
    xml = RestClient.get Dor::Config.sdr.url + "objects/#{druid}/metadata/contentMetadata.xml"
    doc = Nokogiri::XML(xml)
  rescue RestClient::ResourceNotFound
    LOG.info "#{druid} not yet ingested by SDR"
  rescue Exception => e
    LOG.error "Unable to get contentMetadata from SDR for #{druid}\n" << e.inspect
  end
  doc
end

def compare_checksums_with_sdr(druid, file_hash, sdr_cm_doc)
  xsums_to_sym = { 'MD5' => :md5, 'SHA-1' => :sha1}
  xsums_to_sym.keys.each do |xsum_type|
    sdr_xsum_node = sdr_cm_doc.at_xpath %(//file[@id = "#{file_hash[:name]}"]/checksum[@type = "#{xsum_type}"])
    dor_xsum = file_hash[xsums_to_sym[xsum_type]]
    next if (sdr_xsum_node && (sdr_xsum_node.content == dor_xsum))
LOG.warn %(Issue with SDR #{xsum_type} checksum comparison)
      sdr_xsum = sdr_xsum_node ? sdr_xsum_node.content : 'nil'
      LOG.warn %(SDR has: #{sdr_xsum}, DOR has #{file_hash.inspect})
  end
end

def update_wf(druid)
  doc = Nokogiri::XML(Dor::Config.workflow.client.get_workflow_xml('dor', druid, 'accessionWF'))
  errs = doc.xpath('//process[not(@archived) and @status="error"]')
  errs.map{|node| node['name']}.select{|name| name =~ /technical-metadata|shelve/ }.each do |proc|
    Dor::Config.workflow.client.update_workflow_status 'dor', druid, 'accessionWF', proc, 'waiting'
  end
end

def fix(druid_path)
  druids = IO.readlines(druid_path).map {|l| l.strip}

  druids.each do |dr|
    fix_xsums dr
    LOG.info "Finished #{dr}"
  rescue Exception => e
    LOG.error "Skipping #{dr} due to #{e.inspect}\n" << e.backtrace.join("\n")
  end

end

require 'logger'
log_path = File.join ROBOT_ROOT, 'log', 'etd-xsum-fix.log'
LOG = Logger.new(log_path)
