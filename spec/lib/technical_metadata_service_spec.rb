# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TechnicalMetadataService do
  let(:object_ids) { %w[dd116zh0343 du000ps9999 jq937jp0017] }
  let(:druid_tool) { {} }
  let(:tech_metadata) { nil }
  let(:files) { [] }
  let(:content_group_diff) { instance_double(Moab::FileGroupDifference) }
  let(:preservation_technical_metadata) { nil }
  let(:instance) do
    described_class.new(files: files,
                        pid: druid,
                        tech_metadata: tech_metadata,
                        preservation_technical_metadata: preservation_technical_metadata,
                        content_group_diff: content_group_diff)
  end

  let(:druid) { 'druid:dd116zh0343' }

  before do
    fixtures = Pathname(File.dirname(__FILE__)).join('../fixtures')
    wsfixtures = fixtures.join('workspace').to_s
    allow(Settings.sdr).to receive_messages(local_workspace_root: wsfixtures)
    @sdr_repo = fixtures.join('sdr_repo')
    @inventory_differences = {}
    @deltas = {}
    @new_files = {}
    @repo_techmd = {}
    @new_file_techmd = {}
    @expected_techmd = {}

    object_ids.each do |id|
      druid = "druid:#{id}"
      instance = described_class.new(files: [],
                                     pid: druid,
                                     tech_metadata: nil,
                                     preservation_technical_metadata: nil,
                                     content_group_diff: content_group_diff)
      druid_tool[id] = DruidTools::Druid.new(druid, Pathname(wsfixtures).to_s)
      repo_content_pathname = fixtures.join('sdr_repo', id, 'v0001', 'data', 'content')
      work_content_pathname = Pathname(druid_tool[id].content_dir)
      repo_content_inventory = Moab::FileGroup.new(group_id: 'content').group_from_directory(repo_content_pathname)
      work_content_inventory = Moab::FileGroup.new.group_from_directory(work_content_pathname)
      @inventory_differences[id] = Moab::FileGroupDifference.new
      @inventory_differences[id].compare_file_groups(repo_content_inventory, work_content_inventory)
      @deltas[id] = @inventory_differences[id].file_deltas
      @new_files[id] = instance.send(:new_files, @deltas[id])
      @repo_techmd[id] = fixtures.join('sdr_repo', id, 'v0001', 'data', 'metadata', 'technicalMetadata.xml').read
      @new_file_techmd[id] = instance.send(:new_technical_metadata, @deltas[id])
      @expected_techmd[id] = Pathname(druid_tool[id].metadata_dir).join('technicalMetadata.xml').read
    end
  end

  after(:all) do
    object_ids = [] if object_ids.nil?
    object_ids.each do |id|
      temp_pathname = Pathname(druid_tool[id].temp_dir(false))
      temp_pathname.rmtree if temp_pathname.exist?
    end
  end

  describe '.add_update_technical_metadata' do
    # Note: This test is for an experiment and will be removed.
    context 'when all files are not staged' do
      let(:content_group_diff) { instance_double(Moab::FileGroupDifference, file_deltas: { added: [], modified: [] }) }
      let(:files) do
        ['folder1PuSu/story1u.txt', 'folder1PuSu/story2r.txt', 'folder1PuSu/story3m.txt', 'folder1PuSu/story4d.txt', 'folder2PdSa/story6u.txt', 'folder2PdSa/story7r.txt', 'folder2PdSa/story8m.txt', 'folder2PdSa/story9d.txt', 'folder3PaSd/storyBu.txt', 'folder3PaSd/storyCr.txt', 'folder3PaSd/storyDm.txt', 'folder3PaSd/storyEd.txt']
      end

      before do
        allow(Honeybadger).to receive(:notify)
      end

      it 'notifies Honeybadger' do
        instance.add_update_technical_metadata
        expect(Honeybadger).to have_received(:notify).with(/Not all files staged for druid:dd116zh0343 when extracting tech md/)
      end
    end

    # Note: This test is for an experiment and will be removed.
    context 'when all files are staged' do
      let(:files) do
        ['folder1PuSu/story1u.txt', 'folder1PuSu/story2rr.txt', 'folder1PuSu/story3m.txt', 'folder1PuSu/story5a.txt', 'folder2PdSa/story6u.txt', 'folder2PdSa/story7rr.txt', 'folder2PdSa/story8m.txt', 'folder2PdSa/storyAa.txt', 'folder3PaSd/storyBu.txt', 'folder3PaSd/storyCrr.txt', 'folder3PaSd/storyDm.txt', 'folder3PaSd/storyFa.txt']
      end
      let(:content_group_diff) { instance_double(Moab::FileGroupDifference, file_deltas: { added: [], modified: [] }) }

      before do
        allow(Honeybadger).to receive(:notify)
      end

      it 'does not notify Honeybadger' do
        instance.add_update_technical_metadata
        expect(Honeybadger).not_to have_received(:notify)
      end
    end

    # Note: This test is for an experiment and will be removed.
    context 'when no files are staged' do
      let(:druid) { 'druid:bb648mk7250' }
      let(:files) do
        ['folder1PuSu/story1u.txt', 'folder1PuSu/story2rr.txt', 'folder1PuSu/story3m.txt', 'folder1PuSu/story5a.txt']
      end
      let(:content_group_diff) { instance_double(Moab::FileGroupDifference, file_deltas: { added: [], modified: [] }) }

      before do
        allow(Honeybadger).to receive(:notify)
        FileUtils.mkdir_p('spec/fixtures/sdr_repo/bb648mk7250/v0001/data/content')
      end

      after do
        FileUtils.rm_rf('spec/fixtures/sdr_repo/bb648mk7250/v0001/data/content')
      end

      it 'does not notify Honeybadger' do
        instance.add_update_technical_metadata
        expect(Honeybadger).not_to have_received(:notify)
      end
    end
  end

  specify '#new_files' do
    new_files = instance.send(:new_files, @deltas['jq937jp0017'])
    expect(new_files).to eq(['page-2.jpg', 'page-1.jpg'])
  end

  specify '#preserved_or_dor_technical_metadata' do
    tech_md = '<technicalMetadata/>'
    expect(instance).to receive(:preservation_technical_metadata).and_return(tech_md, nil)
    old_techmd = instance.send(:preserved_or_dor_technical_metadata)
    expect(old_techmd).to eq(tech_md)
    expect(instance).to receive(:dor_technical_metadata).and_return(tech_md)
    old_techmd = instance.send(:preserved_or_dor_technical_metadata)
    expect(old_techmd).to eq(tech_md)
  end

  describe '#upgraded_preservation_technical_metadata' do
    subject { instance.send(:upgraded_preservation_technical_metadata) }

    let(:druid) { 'druid:du000ps9999' }

    context 'when preservation metadata returned is nil' do
      let(:preservation_technical_metadata) { nil }

      it { is_expected.to be_nil }
    end

    context 'when preservation metadata has technicalMetadata outer tag' do
      let(:preservation_technical_metadata) { '<technicalMetadata/>' }

      it { is_expected.to eq '<technicalMetadata/>' }
    end

    context 'when preservation metadata has jhove outer tag' do
      let(:preservation_technical_metadata) { '<jhove/>' }

      before do
        jhove_service = instance_double(JhoveService, upgrade_technical_metadata: 'upgraded techmd')
        allow(JhoveService).to receive(:new).and_return(jhove_service)
      end

      it 'gets metadata from jhove service' do
        expect(instance.send(:upgraded_preservation_technical_metadata)).to eq 'upgraded techmd'
        expect(JhoveService).to have_received(:new)
      end
    end
  end

  describe '#dor_technical_metadata' do
    context 'when the tech_metadata is nil' do
      it 'processes the metadata' do
        dor_techmd = instance.send(:dor_technical_metadata)
        expect(dor_techmd).to be_nil
      end
    end

    context 'when the tech_metadata has <technicalMetadata>' do
      let(:tech_metadata) { '<technicalMetadata/>' }

      it 'processes the metadata' do
        dor_techmd = instance.send(:dor_technical_metadata)
        expect(dor_techmd).to eq('<technicalMetadata/>')
      end
    end

    context 'when the tech_metadata has <jhove>' do
      let(:tech_metadata) { '<jhove/>' }
      let(:jhove_service) { instance_double(JhoveService, upgrade_technical_metadata: 'upgraded techmd') }

      before do
        allow(JhoveService).to receive(:new).and_return(jhove_service)
      end

      it 'processes the metadata' do
        dor_techmd = instance.send(:dor_technical_metadata)
        expect(dor_techmd).to eq('upgraded techmd')
      end
    end
  end

  specify '#new_technical_metadata' do
    object_ids.each do |id|
      allow(instance).to receive(:pid).and_return("druid:#{id}")
      new_techmd = instance.send(:new_technical_metadata, @deltas[id])
      file_nodes = Nokogiri::XML(new_techmd).xpath('//file')
      case id
      when 'dd116zh0343'
        expect(file_nodes.size).to eq(6)
      when 'du000ps9999'
        expect(file_nodes.size).to eq(0)
      when 'jq937jp0017'
        expect(file_nodes.size).to eq(2)
      end
    end
  end

  specify '#write_fileset' do
    object_ids.each do |id|
      temp_dir = druid_tool[id].temp_dir
      new_files = @new_files[id]
      filename = instance.send(:write_fileset, temp_dir, new_files)
      if !new_files.empty?
        expect(Pathname(filename).read).to eq(new_files.join("\n") + "\n")
      else
        expect(Pathname(filename).read).to eq('')
      end
    end
  end

  describe '#merge_file_nodes' do
    specify 'when no errors in metadata' do
      object_ids.each do |id|
        old_techmd = @repo_techmd[id]
        new_techmd = @new_file_techmd[id]
        new_nodes = instance.send(:file_nodes, new_techmd)
        deltas = @deltas[id]
        merged_nodes = instance.send(:merge_file_nodes, old_techmd, new_techmd, deltas)
        case id
        when 'dd116zh0343'
          expect(new_nodes.keys.sort). to eq([
                                               'folder1PuSu/story3m.txt',
                                               'folder1PuSu/story5a.txt',
                                               'folder2PdSa/story8m.txt',
                                               'folder2PdSa/storyAa.txt',
                                               'folder3PaSd/storyDm.txt',
                                               'folder3PaSd/storyFa.txt'
                                             ])
          expect(merged_nodes.keys.sort).to eq([
                                                 'folder1PuSu/story1u.txt',
                                                 'folder1PuSu/story2rr.txt',
                                                 'folder1PuSu/story3m.txt',
                                                 'folder1PuSu/story5a.txt',
                                                 'folder2PdSa/story6u.txt',
                                                 'folder2PdSa/story7rr.txt',
                                                 'folder2PdSa/story8m.txt',
                                                 'folder2PdSa/storyAa.txt',
                                                 'folder3PaSd/storyBu.txt',
                                                 'folder3PaSd/storyCrr.txt',
                                                 'folder3PaSd/storyDm.txt',
                                                 'folder3PaSd/storyFa.txt'
                                               ])
        when 'du000ps9999'
          expect(new_nodes.keys.sort). to eq([])
          expect(merged_nodes.keys.sort).to eq(['a1.txt', 'a4.txt', 'a5.txt', 'a6.txt', 'b1.txt'])
        when 'jq937jp0017'
          expect(new_nodes.keys.sort). to eq(['page-1.jpg', 'page-2.jpg'])
          expect(merged_nodes.keys.sort).to eq(['page-1.jpg', 'page-2.jpg', 'page-3.jpg', 'page-4.jpg', 'title.jpg'])
        end
      end
    end

    specify 'when files are missing from existing technical metadata' do
      id = 'dd116zh0343'
      old_techmd = Pathname(druid_tool[id].metadata_dir).join('technicalMetadata-bad.xml').read
      new_techmd = @new_file_techmd[id]
      new_nodes = instance.send(:file_nodes, new_techmd)
      deltas = @deltas[id]
      # Remove folder1PuSu/story1u.txt (identical), folder1PuSu/story2r.txt (renamed) from old_techmd.
      merged_nodes = instance.send(:merge_file_nodes, old_techmd, new_techmd, deltas)
      expect(new_nodes.keys.sort). to eq([
                                           'folder1PuSu/story3m.txt',
                                           'folder1PuSu/story5a.txt',
                                           'folder2PdSa/story8m.txt',
                                           'folder2PdSa/storyAa.txt',
                                           'folder3PaSd/storyDm.txt',
                                           'folder3PaSd/storyFa.txt'
                                         ])
      expect(merged_nodes.keys.sort).to eq([
                                             'folder1PuSu/story3m.txt',
                                             'folder1PuSu/story5a.txt',
                                             'folder2PdSa/story6u.txt',
                                             'folder2PdSa/story7rr.txt',
                                             'folder2PdSa/story8m.txt',
                                             'folder2PdSa/storyAa.txt',
                                             'folder3PaSd/storyBu.txt',
                                             'folder3PaSd/storyCrr.txt',
                                             'folder3PaSd/storyDm.txt',
                                             'folder3PaSd/storyFa.txt'
                                           ])
    end
  end

  specify '#file_nodes' do
    techmd = @repo_techmd['jq937jp0017']
    nodes = instance.send(:file_nodes, techmd)
    expect(nodes.size).to eq(6)
    expect(nodes.keys.sort).to eq(['intro-1.jpg', 'intro-2.jpg', 'page-1.jpg', 'page-2.jpg', 'page-3.jpg', 'title.jpg'])
    expect(nodes['page-1.jpg']).to be_equivalent_to(<<-EOF
    <file id="page-1.jpg">
      <jhove:reportingModule release="1.2" date="2007-02-13">JPEG-hul</jhove:reportingModule>
      <jhove:format>JPEG</jhove:format>
      <jhove:version>1.01</jhove:version>
      <jhove:status>Well-Formed and valid</jhove:status>
      <jhove:sigMatch>
        <jhove:module>JPEG-hul</jhove:module>
      </jhove:sigMatch>
      <jhove:mimeType>image/jpeg</jhove:mimeType>
      <jhove:profiles>
        <jhove:profile>JFIF</jhove:profile>
      </jhove:profiles>
      <jhove:properties>
        <mix:mix>
          <mix:BasicDigitalObjectInformation>
            <mix:byteOrder>big_endian</mix:byteOrder>
            <mix:Compression>
              <mix:compressionScheme>6</mix:compressionScheme>
            </mix:Compression>
          </mix:BasicDigitalObjectInformation>
          <mix:BasicImageInformation>
            <mix:BasicImageCharacteristics>
              <mix:imageWidth>438</mix:imageWidth>
              <mix:imageHeight>478</mix:imageHeight>
              <mix:PhotometricInterpretation>
                <mix:colorSpace>6</mix:colorSpace>
              </mix:PhotometricInterpretation>
            </mix:BasicImageCharacteristics>
          </mix:BasicImageInformation>
          <mix:ImageAssessmentMetadata>
            <mix:SpatialMetrics>
              <mix:samplingFrequencyUnit>2</mix:samplingFrequencyUnit>
              <mix:xSamplingFrequency>
                <mix:numerator>72</mix:numerator>
              </mix:xSamplingFrequency>
              <mix:ySamplingFrequency>
                <mix:numerator>72</mix:numerator>
              </mix:ySamplingFrequency>
            </mix:SpatialMetrics>
            <mix:ImageColorEncoding>
              <mix:bitsPerSample>
                <mix:bitsPerSampleValue>8,8,8</mix:bitsPerSampleValue>
                <mix:bitsPerSampleUnit>integer</mix:bitsPerSampleUnit>
              </mix:bitsPerSample>
              <mix:samplesPerPixel>3</mix:samplesPerPixel>
            </mix:ImageColorEncoding>
          </mix:ImageAssessmentMetadata>
        </mix:mix>
      </jhove:properties>
    </file>
    EOF
                                                   )
  end

  specify '#build_technical_metadata' do
    object_ids.each do |id|
      instance = described_class.new(files: [],
                                     pid: "druid:#{id}",
                                     tech_metadata: nil,
                                     preservation_technical_metadata: nil,
                                     content_group_diff: content_group_diff)
      old_techmd = @repo_techmd[id]
      new_techmd = @new_file_techmd[id]
      deltas = @deltas[id]
      merged_nodes = instance.send(:merge_file_nodes, old_techmd, new_techmd, deltas)

      final_techmd = scrub_techmd(instance.send(:build_technical_metadata, merged_nodes))
      expected_techmd = scrub_techmd(@expected_techmd[id])
      expect(final_techmd).to be_equivalent_to expected_techmd
    end
  end

  def scrub_techmd(techmd)
    # the final and expected_techmd need to be scrubbed of dates in a couple spots for the comparison to match since these will vary from test run to test run
    # "druid:#{id}",
    # Also, need to scrub reporting module versions.
    techmd
      .gsub(/datetime=["'].*?["']/, '')
      .gsub(%r{<jhove:lastModified>.*?</jhove:lastModified>}, '')
      .gsub(/<jhove:reportingModule release='\d+\.\d+(\.\d+)*' date='20\d\d-\d\d-\d\d'>/, "<jhove:reportingModule release='X.X' date='20XX-XX-XX'>")
  end
end
