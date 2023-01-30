# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Accession::ContentMetadata do
  subject(:robot) { described_class.new }

  describe '.perform' do
    subject(:perform) { test_perform(robot, druid) }

    let(:object_client) do
      instance_double(Dor::Services::Client::Object, update: nil, find: object)
    end

    let(:druid) { 'druid:bb123cd4567' }

    before do
      allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    end

    context 'when an item' do
      let(:object) { build(:dro, id: druid).new(access: access) }
      let(:access) { {} }

      context 'when no contentMetadata.xml file is found' do
        it 'does not update the object and returns status skipped' do
          expect(perform.status).to eq 'skipped'
          expect(object_client).not_to have_received(:update)
        end
      end

      context 'when contentMetadata file is found' do
        let(:finder) { instance_double(DruidTools::Druid, find_metadata: 'spec/fixtures/workspace/ab/123/cd/4567/content_metadata.xml') }

        before do
          allow(DruidTools::Druid).to receive(:new).and_return(finder)
        end

        context 'with dark access' do
          let(:access) { { view: 'dark', download: 'none' } }

          it 'builds the structural metadata and casts files to preserve only' do
            perform

            expect(object_client).to have_received(:update).with(params: Cocina::Models::DRO) do |model|
              actions = model[:params].structural.contains.map { |file_set| file_set.structural.contains.map { |file| [file.administrative.publish, file.administrative.shelve, file.administrative.sdrPreserve] } }
              expect(actions).to eq [[[false, false, true], [false, false, true]], [[false, false, true], [false, false, true]]]
            end
          end
        end

        context 'with non-dark access' do
          let(:access) { { view: 'world', download: 'stanford' } }

          it 'builds the structural metadata and retains the original publish/shelve/preserve' do
            perform

            expect(object_client).to have_received(:update).with(params: Cocina::Models::DRO) do |model|
              actions = model[:params].structural.contains.map { |file_set| file_set.structural.contains.map { |file| [file.administrative.publish, file.administrative.shelve, file.administrative.sdrPreserve] } }
              expect(actions).to eq [[[true, false, true], [false, true, true]], [[true, false, true], [false, true, true]]]
            end
          end
        end
      end
    end

    context 'when a collection' do
      let(:object) { build(:collection, id: druid) }

      it "doesn't update the object" do
        perform
        expect(object_client).not_to have_received(:update)
      end
    end
  end
end
