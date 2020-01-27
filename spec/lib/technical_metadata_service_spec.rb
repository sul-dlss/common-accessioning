# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TechnicalMetadataService do
  let(:object_ids) { %w[dd116zh0343 du000ps9999 jq937jp0017] }
  let(:druid_tool) { {} }
  let(:instance) { described_class.new(dor_item) }
  let(:dor_item) { instance_double(Dor::Item, pid: druid, contentMetadata: nil) }
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
      instance = described_class.new(instance_double(Dor::Item, pid: druid))
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
      let(:technicalMetadata) { instance_double(Dor::TechnicalMetadataDS, new?: true, :dsLabel= => true, :content= => true, save: true) }
      let(:dor_item) { instance_double(Dor::Item, pid: druid, contentMetadata: contentMetadata, datastreams: { 'technicalMetadata' => technicalMetadata }) }
      let(:contentMetadata) { instance_double(Dor::ContentMetadataDS, content: contentMetadataContent) }
      let(:contentMetadataContent) do
        <<~EOF
          <?xml version="1.0"?>
          <contentMetadata type="sample" objectId="druid:dd116zh0343">
            <resource sequence="1" type="folder" id="folder1PuSu">
              <file shelve="yes" publish="yes" size="7888" preserve="yes" datetime="2012-06-15T22:57:43Z" id="folder1PuSu/story1u.txt">
                <checksum type="MD5">e2837b9f02e0b0b76f526eeb81c7aa7b</checksum>
                <checksum type="SHA-1">61dfac472b7904e1413e0cbf4de432bda2a97627</checksum>
              </file>
              <file shelve="yes" publish="yes" size="5983" preserve="yes" datetime="2012-06-15T22:58:56Z" id="folder1PuSu/story2r.txt">
                <checksum type="MD5">dc2be64ae43f1c1db4a068603465955d</checksum>
                <checksum type="SHA-1">b8a672c1848fc3d13b5f380e15835690e24600e0</checksum>
              </file>
              <file shelve="yes" publish="yes" size="5951" preserve="yes" datetime="2012-06-15T23:00:43Z" id="folder1PuSu/story3m.txt">
                <checksum type="MD5">3d67f52e032e36b641d0cad40816f048</checksum>
                <checksum type="SHA-1">548f349c79928b6d0996b7ff45990bdce5ee9753</checksum>
              </file>
              <file shelve="yes" publish="yes" size="6307" preserve="yes" datetime="2012-06-15T23:02:22Z" id="folder1PuSu/story4d.txt">
                <checksum type="MD5">34f3f646523b0a8504f216483a57bce4</checksum>
                <checksum type="SHA-1">d498b513add5bb138ed4f6205453a063a2434dc4</checksum>
              </file>
            </resource>
            <resource sequence="2" type="folder" id="folder2PdSa">
              <file shelve="no" publish="yes" size="2534" preserve="yes" datetime="2012-06-15T23:05:03Z" id="folder2PdSa/story6u.txt">
                <checksum type="MD5">1f15cc786bfe832b2fa1e6f047c500ba</checksum>
                <checksum type="SHA-1">bf3af01de2afa15719d8c42a4141e3b43d06fef6</checksum>
              </file>
              <file shelve="no" publish="yes" size="17074" preserve="yes" datetime="2012-06-15T23:08:35Z" id="folder2PdSa/story7r.txt">
                <checksum type="MD5">205271287477c2309512eb664eff9130</checksum>
                <checksum type="SHA-1">b23aa592ab673030ace6178e29fad3cf6a45bd32</checksum>
              </file>
              <file shelve="no" publish="yes" size="5643" preserve="yes" datetime="2012-06-15T23:09:26Z" id="folder2PdSa/story8m.txt">
                <checksum type="MD5">ce474f4c512953f20a8c4c5b92405cf7</checksum>
                <checksum type="SHA-1">af9cbf5ab4f020a8bb17b180fbd5c41598d89b37</checksum>
              </file>
              <file shelve="no" publish="yes" size="19599" preserve="yes" datetime="2012-06-15T23:14:32Z" id="folder2PdSa/story9d.txt">
                <checksum type="MD5">135cb2db6a35afac590687f452053baf</checksum>
                <checksum type="SHA-1">e74274d7bc06ef44a408a008f5160b3756cb2ab0</checksum>
              </file>
            </resource>
            <resource sequence="3" type="folder" id="folder3PaSd">
              <file shelve="yes" publish="yes" size="14964" preserve="no" datetime="2012-06-17T11:42:52Z" id="folder3PaSd/storyBu.txt">
                <checksum type="MD5">8f0a828f3e63cd18232c191ab0c5805c</checksum>
                <checksum type="SHA-1">b6cb7aa60dd07b4dcc6ab709437e574912f25f30</checksum>
              </file>
              <file shelve="yes" publish="yes" size="23485" preserve="no" datetime="2012-06-17T11:44:14Z" id="folder3PaSd/storyCr.txt">
                <checksum type="MD5">3486492e40b4c342b25ae4f9c64f06ee</checksum>
                <checksum type="SHA-1">a1654e9d3cf80242cc3669f89fb41b2ec5e62cb7</checksum>
              </file>
              <file shelve="yes" publish="yes" size="25336" preserve="no" datetime="2012-06-17T11:45:56Z" id="folder3PaSd/storyDm.txt">
                <checksum type="MD5">233228c7e1f473dad1d2c673157dd809</checksum>
                <checksum type="SHA-1">83c57f595aa6a72f80d47900cc0d10e589f31ea5</checksum>
              </file>
              <file shelve="yes" publish="yes" size="41765" preserve="no" datetime="2012-06-17T11:49:53Z" id="folder3PaSd/storyEd.txt">
                <checksum type="MD5">0e57176032451fd6d0509b6172790b8f</checksum>
                <checksum type="SHA-1">b191e11dc1768c47852e6d2a235094843be358ff</checksum>
              </file>
            </resource>
          </contentMetadata>
        EOF
      end
      let(:inventory_diff) { instance_double(Moab::FileInventoryDifference, group_difference: file_group_diff) }
      let(:file_group_diff) { instance_double(Moab::FileGroupDifference, file_deltas: { added: [], modified: [] }) }

      before do
        allow(Preservation::Client.objects).to receive(:metadata)
        allow(Preservation::Client.objects).to receive(:content_inventory_diff).and_return(inventory_diff)
        allow(Honeybadger).to receive(:notify)
      end

      it 'notifies Honeybadger' do
        instance.add_update_technical_metadata
        expect(Honeybadger).to have_received(:notify).with(/Not all files staged for druid:dd116zh0343 when extracting tech md/)
      end
    end

    # Note: This test is for an experiment and will be removed.
    context 'when all files are staged' do
      let(:technicalMetadata) { instance_double(Dor::TechnicalMetadataDS, new?: true, :dsLabel= => true, :content= => true, save: true) }
      let(:dor_item) { instance_double(Dor::Item, pid: druid, contentMetadata: contentMetadata, datastreams: { 'technicalMetadata' => technicalMetadata }) }
      let(:contentMetadata) { instance_double(Dor::ContentMetadataDS, content: contentMetadataContent) }
      let(:contentMetadataContent) do
        <<~EOF
          <?xml version="1.0"?>
          <contentMetadata type="sample" objectId="druid:dd116zh0343">
            <resource sequence="1" type="folder" id="folder1PuSu">
              <file shelve="yes" publish="yes" size="7888" preserve="yes" datetime="2012-06-15T22:57:43Z" id="folder1PuSu/story1u.txt">
                <checksum type="MD5">e2837b9f02e0b0b76f526eeb81c7aa7b</checksum>
                <checksum type="SHA-1">61dfac472b7904e1413e0cbf4de432bda2a97627</checksum>
              </file>
              <file shelve="yes" publish="yes" size="5983" preserve="yes" datetime="2012-06-15T22:58:56Z" id="folder1PuSu/story2rr.txt">
                <checksum type="MD5">dc2be64ae43f1c1db4a068603465955d</checksum>
                <checksum type="SHA-1">b8a672c1848fc3d13b5f380e15835690e24600e0</checksum>
              </file>
              <file shelve="yes" publish="yes" size="5951" preserve="yes" datetime="2012-06-15T23:00:43Z" id="folder1PuSu/story3m.txt">
                <checksum type="MD5">3d67f52e032e36b641d0cad40816f048</checksum>
                <checksum type="SHA-1">548f349c79928b6d0996b7ff45990bdce5ee9753</checksum>
              </file>
              <file shelve="yes" publish="yes" size="6307" preserve="yes" datetime="2012-06-15T23:02:22Z" id="folder1PuSu/story5a.txt">
                <checksum type="MD5">34f3f646523b0a8504f216483a57bce4</checksum>
                <checksum type="SHA-1">d498b513add5bb138ed4f6205453a063a2434dc4</checksum>
              </file>
            </resource>
            <resource sequence="2" type="folder" id="folder2PdSa">
              <file shelve="no" publish="yes" size="2534" preserve="yes" datetime="2012-06-15T23:05:03Z" id="folder2PdSa/story6u.txt">
                <checksum type="MD5">1f15cc786bfe832b2fa1e6f047c500ba</checksum>
                <checksum type="SHA-1">bf3af01de2afa15719d8c42a4141e3b43d06fef6</checksum>
              </file>
              <file shelve="no" publish="yes" size="17074" preserve="yes" datetime="2012-06-15T23:08:35Z" id="folder2PdSa/story7rr.txt">
                <checksum type="MD5">205271287477c2309512eb664eff9130</checksum>
                <checksum type="SHA-1">b23aa592ab673030ace6178e29fad3cf6a45bd32</checksum>
              </file>
              <file shelve="no" publish="yes" size="5643" preserve="yes" datetime="2012-06-15T23:09:26Z" id="folder2PdSa/story8m.txt">
                <checksum type="MD5">ce474f4c512953f20a8c4c5b92405cf7</checksum>
                <checksum type="SHA-1">af9cbf5ab4f020a8bb17b180fbd5c41598d89b37</checksum>
              </file>
              <file shelve="no" publish="yes" size="19599" preserve="yes" datetime="2012-06-15T23:14:32Z" id="folder2PdSa/storyAa.txt">
                <checksum type="MD5">135cb2db6a35afac590687f452053baf</checksum>
                <checksum type="SHA-1">e74274d7bc06ef44a408a008f5160b3756cb2ab0</checksum>
              </file>
            </resource>
            <resource sequence="3" type="folder" id="folder3PaSd">
              <file shelve="yes" publish="yes" size="14964" preserve="no" datetime="2012-06-17T11:42:52Z" id="folder3PaSd/storyBu.txt">
                <checksum type="MD5">8f0a828f3e63cd18232c191ab0c5805c</checksum>
                <checksum type="SHA-1">b6cb7aa60dd07b4dcc6ab709437e574912f25f30</checksum>
              </file>
              <file shelve="yes" publish="yes" size="23485" preserve="no" datetime="2012-06-17T11:44:14Z" id="folder3PaSd/storyCrr.txt">
                <checksum type="MD5">3486492e40b4c342b25ae4f9c64f06ee</checksum>
                <checksum type="SHA-1">a1654e9d3cf80242cc3669f89fb41b2ec5e62cb7</checksum>
              </file>
              <file shelve="yes" publish="yes" size="25336" preserve="no" datetime="2012-06-17T11:45:56Z" id="folder3PaSd/storyDm.txt">
                <checksum type="MD5">233228c7e1f473dad1d2c673157dd809</checksum>
                <checksum type="SHA-1">83c57f595aa6a72f80d47900cc0d10e589f31ea5</checksum>
              </file>
              <file shelve="yes" publish="yes" size="41765" preserve="no" datetime="2012-06-17T11:49:53Z" id="folder3PaSd/storyFa.txt">
                <checksum type="MD5">0e57176032451fd6d0509b6172790b8f</checksum>
                <checksum type="SHA-1">b191e11dc1768c47852e6d2a235094843be358ff</checksum>
              </file>
            </resource>
          </contentMetadata>
        EOF
      end
      let(:inventory_diff) { instance_double(Moab::FileInventoryDifference, group_difference: file_group_diff) }
      let(:file_group_diff) { instance_double(Moab::FileGroupDifference, file_deltas: { added: [], modified: [] }) }

      before do
        allow(Preservation::Client.objects).to receive(:metadata)
        allow(Preservation::Client.objects).to receive(:content_inventory_diff).and_return(inventory_diff)
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
      let(:technicalMetadata) { instance_double(Dor::TechnicalMetadataDS, new?: true, :dsLabel= => true, :content= => true, save: true) }
      let(:dor_item) { instance_double(Dor::Item, pid: druid, contentMetadata: contentMetadata, datastreams: { 'technicalMetadata' => technicalMetadata }) }
      let(:contentMetadata) { instance_double(Dor::ContentMetadataDS, content: contentMetadataContent) }
      let(:contentMetadataContent) do
        <<~EOF
          <?xml version="1.0"?>
          <contentMetadata type="sample" objectId="druid:bb648mk7250">
            <resource sequence="1" type="folder" id="folder1PuSu">
              <file shelve="yes" publish="yes" size="7888" preserve="yes" datetime="2012-06-15T22:57:43Z" id="folder1PuSu/story1u.txt">
                <checksum type="MD5">e2837b9f02e0b0b76f526eeb81c7aa7b</checksum>
                <checksum type="SHA-1">61dfac472b7904e1413e0cbf4de432bda2a97627</checksum>
              </file>
              <file shelve="yes" publish="yes" size="5983" preserve="yes" datetime="2012-06-15T22:58:56Z" id="folder1PuSu/story2rr.txt">
                <checksum type="MD5">dc2be64ae43f1c1db4a068603465955d</checksum>
                <checksum type="SHA-1">b8a672c1848fc3d13b5f380e15835690e24600e0</checksum>
              </file>
              <file shelve="yes" publish="yes" size="5951" preserve="yes" datetime="2012-06-15T23:00:43Z" id="folder1PuSu/story3m.txt">
                <checksum type="MD5">3d67f52e032e36b641d0cad40816f048</checksum>
                <checksum type="SHA-1">548f349c79928b6d0996b7ff45990bdce5ee9753</checksum>
              </file>
              <file shelve="yes" publish="yes" size="6307" preserve="yes" datetime="2012-06-15T23:02:22Z" id="folder1PuSu/story5a.txt">
                <checksum type="MD5">34f3f646523b0a8504f216483a57bce4</checksum>
                <checksum type="SHA-1">d498b513add5bb138ed4f6205453a063a2434dc4</checksum>
              </file>
            </resource>
          </contentMetadata>
        EOF
      end
      let(:inventory_diff) { instance_double(Moab::FileInventoryDifference, group_difference: file_group_diff) }
      let(:file_group_diff) { instance_double(Moab::FileGroupDifference, file_deltas: { added: [], modified: [] }) }

      before do
        allow(Preservation::Client.objects).to receive(:metadata)
        allow(Preservation::Client.objects).to receive(:content_inventory_diff).and_return(inventory_diff)
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

    context 'when old technical metadata is nil' do
      # Old technical metadata is nil because technicalMetadata is new and because Preservation returns nothing.
      let(:technicalMetadata) { instance_double(Dor::TechnicalMetadataDS, new?: true, :dsLabel= => true, :content= => true, save: true) }
      let(:dor_item) { instance_double(Dor::Item, pid: druid, contentMetadata: contentMetadata, datastreams: { 'technicalMetadata' => technicalMetadata }) }
      let(:contentMetadata) { instance_double(Dor::ContentMetadataDS, content: '') }
      let(:inventory_diff) { instance_double(Moab::FileInventoryDifference, group_difference: file_group_diff) }
      let(:file_group_diff) { instance_double(Moab::FileGroupDifference, file_deltas: { added: [], modified: [] }) }

      before do
        allow(Preservation::Client.objects).to receive(:metadata)
        allow(Preservation::Client.objects).to receive(:content_inventory_diff).and_return(inventory_diff)
      end

      it 'stores' do
        instance.add_update_technical_metadata
        expect(technicalMetadata).to have_received(:save)
      end
    end

    specify 'when save is successful' do
      object_ids.each do |id|
        instance = described_class.new(dor_item)
        allow(dor_item).to receive(:pid).and_return("druid:#{id}")
        expect(instance).to receive(:content_group_diff).and_return(@inventory_differences[id])
        expect(@inventory_differences[id]).to receive(:file_deltas).and_return(@deltas[id])
        expect(instance).to receive(:old_technical_metadata).and_return(@repo_techmd[id])
        expect(instance).to receive(:new_technical_metadata).with(Hash).and_return(@new_file_techmd[id])
        mock_datastream = instance_double(Dor::TechnicalMetadataDS, save: true)
        ds_hash = { 'technicalMetadata' => mock_datastream }
        allow(dor_item).to receive(:datastreams).and_return(ds_hash)
        unless @inventory_differences[id].difference_count == 0
          expect(mock_datastream).to receive(:dsLabel=).with('Technical Metadata')
          expect(mock_datastream).to receive(:content=).with(/<technicalMetadata/)
          expect(mock_datastream).to receive(:save)
        end
        instance.add_update_technical_metadata
      end
    end

    specify 'when it cannot save the datastream' do
      object_ids.each do |id|
        allow(dor_item).to receive(:pid).and_return("druid:#{id}")
        expect(instance).to receive(:content_group_diff).and_return(@inventory_differences[id])
        expect(@inventory_differences[id]).to receive(:file_deltas).and_return(@deltas[id])
        expect(instance).to receive(:old_technical_metadata).and_return(@repo_techmd[id])
        expect(instance).to receive(:new_technical_metadata).with(Hash).and_return(@new_file_techmd[id])
        mock_datastream = double('datastream', save: false)
        ds_hash = { 'technicalMetadata' => mock_datastream }
        allow(dor_item).to receive(:datastreams).and_return(ds_hash)
        unless @inventory_differences[id].difference_count == 0
          expect(mock_datastream).to receive(:dsLabel=).with('Technical Metadata')
          expect(mock_datastream).to receive(:content=).with(/<technicalMetadata/)
          expect(mock_datastream).to receive(:save)
        end
        err_regex = /problem saving ActiveFedora::Datastream technicalMetadata for druid:#{id}/
        expect { instance.add_update_technical_metadata }.to raise_error(RuntimeError, err_regex)
      end
    end
  end

  describe '#content_group_diff' do
    subject(:content_group_diff) { instance.send(:content_group_diff) }

    context 'with contentMetadata' do
      let(:contentMetadata) { instance_double(Dor::ContentMetadataDS, content: 'foo') }
      let(:object_id) { 'dd116zh0343' }
      let(:druid) { "druid:#{object_id}" }
      let(:group_diff) { @inventory_differences[object_id] }
      let(:dor_item) { instance_double(Dor::Item, contentMetadata: contentMetadata, pid: druid) }
      let(:inventory_diff) do
        Moab::FileInventoryDifference.new(
          digital_object_id: druid,
          basis: 'old_content_metadata',
          other: 'new_content_metadata',
          report_datetime: Time.now.utc.to_s
        ).tap { |diff| diff.group_differences << group_diff }
      end

      before do
        allow(Preservation::Client.objects).to receive(:content_inventory_diff).and_return(inventory_diff)
      end

      it 'calculates the difference' do
        expect(content_group_diff.to_xml).to eq(group_diff.to_xml)
      end
    end

    context 'without contentMetadata' do
      let(:dor_item) { instance_double(Dor::Item, contentMetadata: nil) }

      it 'has no difference' do
        expect(content_group_diff.difference_count).to be_zero
      end
    end
  end

  specify '#new_files' do
    new_files = instance.send(:new_files, @deltas['jq937jp0017'])
    expect(new_files).to eq(['page-2.jpg', 'page-1.jpg'])
  end

  specify '#old_technical_metadata' do
    druid = 'druid:dd116zh0343'
    allow(dor_item).to receive(:pid).and_return(druid)
    tech_md = '<technicalMetadata/>'
    expect(instance).to receive(:preservation_technical_metadata).and_return(tech_md, nil)
    old_techmd = instance.send(:old_technical_metadata)
    expect(old_techmd).to eq(tech_md)
    expect(instance).to receive(:dor_technical_metadata).and_return(tech_md)
    old_techmd = instance.send(:old_technical_metadata)
    expect(old_techmd).to eq(tech_md)
  end

  describe '#preservation_technical_metadata' do
    let(:druid) { 'druid:du000ps9999' }

    context 'when Preservation::Client does not get 404 from API' do
      subject { instance.send(:preservation_technical_metadata) }

      before do
        allow(Preservation::Client.objects).to receive(:metadata).and_return(metadata)
      end

      context 'when preservation metadata returned is nil' do
        let(:metadata) { nil }

        it { is_expected.to be_nil }
      end

      context 'when preservation metadata has technicalMetadata outer tag' do
        let(:metadata) { '<technicalMetadata/>' }

        it { is_expected.to eq '<technicalMetadata/>' }
      end

      context 'when preservation metadata has jhove outer tag' do
        let(:metadata) { '<jhove/>' }

        before do
          jhove_service = instance_double(JhoveService, upgrade_technical_metadata: 'upgraded techmd')
          allow(JhoveService).to receive(:new).and_return(jhove_service)
        end

        it 'gets metadata from jhove service' do
          expect(instance.send(:preservation_technical_metadata)).to eq 'upgraded techmd'
          expect(JhoveService).to have_received(:new)
        end
      end
    end

    context 'when Preservation::Client gets 404 from API' do
      before do
        errmsg = "Preservation::Client.file for #{druid} got Not Found (404) from Preservation ... 404 Not Found ..."
        allow(Preservation::Client.objects).to receive(:metadata)
          .and_raise(Preservation::Client::NotFoundError, errmsg)
        allow(JhoveService).to receive(:new)
      end

      it 'returns nil and does not call JhoveService' do
        expect(instance.send(:preservation_technical_metadata)).to eq nil
        expect(JhoveService).not_to have_received(:new)
      end
    end
  end

  specify '#dor_technical_metadata' do
    tech_ds = instance_double(Dor::TechnicalMetadataDS)
    allow(tech_ds).to receive(:content).and_return('<technicalMetadata/>')
    datastreams = { 'technicalMetadata' => tech_ds }
    allow(dor_item).to receive(:datastreams).and_return(datastreams)

    allow(tech_ds).to receive(:new?).and_return(true)
    dor_techmd = instance.send(:dor_technical_metadata)
    expect(dor_techmd).to be_nil

    allow(tech_ds).to receive(:new?).and_return(false)
    dor_techmd = instance.send(:dor_technical_metadata)
    expect(dor_techmd).to eq('<technicalMetadata/>')

    allow(tech_ds).to receive(:content).and_return('<jhove/>')
    jhove_service = double(JhoveService)
    allow(JhoveService).to receive(:new).and_return(jhove_service)
    allow(jhove_service).to receive(:upgrade_technical_metadata).and_return('upgraded techmd')
    dor_techmd = instance.send(:dor_technical_metadata)
    expect(dor_techmd).to eq('upgraded techmd')
  end

  specify '#new_technical_metadata' do
    object_ids.each do |id|
      allow(dor_item).to receive(:pid).and_return("druid:#{id}")
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
      instance = described_class.new(instance_double(Dor::Item, pid: "druid:#{id}"))
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
