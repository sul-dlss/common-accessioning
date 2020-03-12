# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dor::Etd::IdentityMetadataGenerator do
  subject(:generate) { described_class.generate(etd) }

  let(:etd) { Etd.new(pid: druid) }
  let(:druid) { 'druid:ab123cd4567' }
  let(:new_uuid) { UUIDTools::UUID.timestamp_create }
  let(:old_id_metadata) { instance_double('identityMetadata') }

  before do
    allow(etd).to receive(:dissertation_id).and_return('0000005666')
    allow(etd).to receive(:etd_type).and_return('Dissertation')

    allow(etd).to receive(:identityMetadata).and_return(old_id_metadata)
    allow(UUIDTools::UUID).to receive(:timestamp_create).and_return(new_uuid)
  end

  describe '.generate' do
    context 'when creating identityMetadata' do
      before do
        allow(old_id_metadata).to receive(:new?).and_return(true)
      end

      it 'generates xml' do
        expect(generate).to be_equivalent_to <<~XML
          <?xml version="1.0"?>
          <identityMetadata>
            <objectId>druid:ab123cd4567</objectId>
            <objectType>item</objectType>
            <objectLabel></objectLabel>
            <objectCreator>DOR</objectCreator>
            <otherId name="dissertationid">0000005666</otherId>
            <otherId name="catkey"/>
            <otherId name="uuid">#{new_uuid}</otherId>
            <agreementId>druid:ct692vv3660</agreementId>
            <objectAdminClass>ETDs</objectAdminClass>
            <tag>ETD : Dissertation</tag>
          </identityMetadata>
        XML
      end
    end

    context 'when updating identityMetadata' do
      before do
        allow(old_id_metadata).to receive(:new?).and_return(false)
        allow(old_id_metadata).to receive(:content).and_return(prev_xml)
      end

      context 'when catkey element in previous xml' do
        let(:prev_xml) do
          <<~XML
            <identityMetadata>
              <catkey>666</catkey>
            </identityMetadata>
          XML
        end

        it 'includes catkey value' do
          expect(generate).to include('<otherId name="catkey">666</otherId>')
        end
      end

      context 'when catkey via otherId[@name="catkey"]' do
        let(:prev_xml) do
          <<~XML
            <identityMetadata>
              <otherId name='catkey'>999</otherId>
            </identityMetadata>
          XML
        end

        it 'includes catkey value' do
          expect(generate).to include('<otherId name="catkey">999</otherId>')
        end
      end

      context 'when previous uuid via otherId[@name="uuid"]' do
        let(:prev_xml) do
          <<~XML
            <identityMetadata>
              <otherId name='uuid'>i-are-a-uuid</otherId>
              <catkey>666</catkey>
            </identityMetadata>
          XML
        end

        it 'includes previous uuid value' do
          expect(generate).to include('<otherId name="uuid">i-are-a-uuid</otherId>')
        end
      end

      context 'when previous uuid was blank' do
        let(:prev_xml) do
          <<~XML
            <identityMetadata>
              <otherId name='uuid'></otherId>
              <catkey>666</catkey>
            </identityMetadata>
          XML
        end

        it 'creates new uuid value' do
          expect(generate).to include("<otherId name=\"uuid\">#{new_uuid}</otherId>")
        end
      end

      context 'when no previous uuid' do
        let(:prev_xml) do
          <<~XML
            <identityMetadata>
              <catkey>666</catkey>
            </identityMetadata>
          XML
        end

        it 'creates new uuid value' do
          expect(generate).to include("<otherId name=\"uuid\">#{new_uuid}</otherId>")
        end
      end
    end
  end
end
