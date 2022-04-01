# frozen_string_literal: true

RSpec.describe Dor::StructuralMetadata do
  context 'with book data' do
    subject(:updated_structural) { described_class.update(content_xml, cocina_object) }

    let(:content_xml) do
      <<~XML
        <contentMetadata type="book" objectId="#{druid}">
          <bookData readingOrder="ltr"/>
          <resource sequence="1" type="file" id="folder1PuSu">
            <label>Folder 1</label>
            <file mimetype="text/plain" shelve="yes" publish="yes" size="7888" preserve="no" id="folder1PuSu/story1u.txt">
              <checksum type="md5">e2837b9f02e0b0b76f526eeb81c7aa7b</checksum>
              <checksum type="sha1">61dfac472b7904e1413e0cbf4de432bda2a97627</checksum>
            </file>
            <file mimetype="text/plain" shelve="no" publish="no" size="5983" preserve="yes" id="folder1PuSu/story2r.txt">
              <checksum type="md5">dc2be64ae43f1c1db4a068603465955d</checksum>
              <checksum type="sha1">b8a672c1848fc3d13b5f380e15835690e24600e0</checksum>
            </file>
            <file mimetype="text/plain" shelve="yes" publish="yes" size="5951" preserve="yes" id="folder1PuSu/story3m.txt">
              <checksum type="md5">3d67f52e032e36b641d0cad40816f048</checksum>
              <checksum type="sha1">548f349c79928b6d0996b7ff45990bdce5ee9753</checksum>
            </file>
            <file mimetype="text/plain" shelve="yes" publish="yes" size="6307" preserve="yes" id="folder1PuSu/story4d.txt">
              <checksum type="md5">34f3f646523b0a8504f216483a57bce4</checksum>
              <checksum type="sha1">d498b513add5bb138ed4f6205453a063a2434dc4</checksum>
            </file>
          </resource>
          <resource sequence="2" type="file" id="folder2PdSa">
            <file mimetype="text/plain" shelve="no" publish="yes" size="2534" preserve="yes" id="folder2PdSa/story6u.txt">
              <checksum type="md5">1f15cc786bfe832b2fa1e6f047c500ba</checksum>
              <checksum type="sha1">bf3af01de2afa15719d8c42a4141e3b43d06fef6</checksum>
            </file>
            <file mimetype="text/plain" shelve="no" publish="yes" size="17074" preserve="yes" id="folder2PdSa/story7r.txt">
              <checksum type="md5">205271287477c2309512eb664eff9130</checksum>
              <checksum type="sha1">b23aa592ab673030ace6178e29fad3cf6a45bd32</checksum>
            </file>
            <file mimetype="text/plain" shelve="no" publish="yes" size="5643" preserve="yes" id="folder2PdSa/story8m.txt">
              <checksum type="md5">ce474f4c512953f20a8c4c5b92405cf7</checksum>
              <checksum type="sha1">af9cbf5ab4f020a8bb17b180fbd5c41598d89b37</checksum>
            </file>
            <file mimetype="text/plain" shelve="no" publish="yes" size="19599" preserve="yes" id="folder2PdSa/story9d.txt">
              <checksum type="md5">135cb2db6a35afac590687f452053baf</checksum>
              <checksum type="sha1">e74274d7bc06ef44a408a008f5160b3756cb2ab0</checksum>
            </file>
          </resource>
        </contentMetadata>
      XML
    end

    let(:apo_druid) { 'druid:pp000pp0000' }
    let(:druid) { 'druid:bc123dg9393' }

    let(:cocina_object) do
      Cocina::Models::DRO.new(externalIdentifier: druid,
                              type: Cocina::Models::ObjectType.object,
                              label: 'Something',
                              version: 1,
                              description: {
                                title: [{ value: 'Something' }],
                                purl: "https://purl.stanford.edu/#{druid.delete_prefix('druid:')}"
                              },
                              identification: { sourceId: 'sul:1234' },
                              access: access,
                              administrative: { hasAdminPolicy: apo_druid },
                              structural: {})
    end

    context 'when the parent object access is world/stanford' do
      let(:access) do
        {
          view: 'world',
          download: 'stanford'
        }
      end

      it 'copies the object access to the files' do
        expect(updated_structural.hasMemberOrders.first.viewingDirection).to eq 'left-to-right'
        expect(updated_structural.contains.size).to eq 2
        file1 = updated_structural.contains.last.structural.contains.last
        expect(file1.label).to eq 'folder2PdSa/story9d.txt'
        # files inherit the object access
        expect(file1.access).to eq Cocina::Models::FileAccess.new(view: 'world', download: 'stanford')
      end
    end

    context 'when the parent object access is citation-only/none' do
      let(:access) do
        {
          view: 'citation-only',
          download: 'none'
        }
      end

      it 'copies the object access to the files' do
        expect(updated_structural.hasMemberOrders.first.viewingDirection).to eq 'left-to-right'
        expect(updated_structural.contains.size).to eq 2
        file1 = updated_structural.contains.last.structural.contains.last
        expect(file1.label).to eq 'folder2PdSa/story9d.txt'
        # citation-only is not inheritable, it should be dark:
        expect(file1.access).to eq Cocina::Models::FileAccess.new(view: 'dark', download: 'none')
      end
    end

    context 'when reading direction is missing' do
      let(:content_xml) do
        <<~XML
          <contentMetadata type="book" objectId="#{druid}">
            <resource sequence="1" type="file" id="folder1PuSu">
              <label>Folder 1</label>
              <file mimetype="text/plain" shelve="yes" publish="yes" size="7888" preserve="no" id="folder1PuSu/story1u.txt">
                <checksum type="md5">e2837b9f02e0b0b76f526eeb81c7aa7b</checksum>
                <checksum type="sha1">61dfac472b7904e1413e0cbf4de432bda2a97627</checksum>
              </file>
              <file mimetype="text/plain" shelve="yes" publish="yes" size="6307" preserve="yes" id="folder1PuSu/story4d.txt">
                <checksum type="md5">34f3f646523b0a8504f216483a57bce4</checksum>
                <checksum type="sha1">d498b513add5bb138ed4f6205453a063a2434dc4</checksum>
              </file>
            </resource>
            <resource sequence="2" type="file" id="folder2PdSa">
              <file mimetype="text/plain" shelve="no" publish="yes" size="2534" preserve="yes" id="folder2PdSa/story6u.txt">
                <checksum type="md5">1f15cc786bfe832b2fa1e6f047c500ba</checksum>
                <checksum type="sha1">bf3af01de2afa15719d8c42a4141e3b43d06fef6</checksum>
              </file>
              <file mimetype="text/plain" shelve="no" publish="yes" size="17074" preserve="yes" id="folder2PdSa/story7r.txt">
                <checksum type="md5">205271287477c2309512eb664eff9130</checksum>
                <checksum type="sha1">b23aa592ab673030ace6178e29fad3cf6a45bd32</checksum>
              </file>
            </resource>
          </contentMetadata>
        XML
      end
      let(:access) do
        {
          view: 'world',
          download: 'stanford'
        }
      end

      before do
        allow(Honeybadger).to receive(:notify)
      end

      it 'notifies Honeybadger, does not raise an error, and uses left-to-right' do
        expect(updated_structural.hasMemberOrders.first.viewingDirection).to eq 'left-to-right'
        exp_hb_warning = "[WARNING] reading direction in contentMetadata.xml is ''; defaulting to ltr"
        expect(Honeybadger).to have_received(:notify).with(exp_hb_warning)
        expect(updated_structural.contains.size).to eq 2
      end
    end
  end
end
