# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Accession::Stage do
  subject(:robot) { described_class.new }

  describe '.perform' do
    subject(:perform) { test_perform(robot, druid) }

    let(:druid) { 'druid:dd116zh0343' }
    let(:object_client) { instance_double(Dor::Services::Client::Object, find: object) }
    let(:workflow_client) { instance_double(Dor::Workflow::Client) }
    let(:workspace_root) { File.join(Dir.tmpdir, 'workspace') }
    let(:object_workspace_root) { "#{workspace_root}/dd/116/zh/0343/dd116zh0343" }

    let(:object) { build(:dro, id: druid) }

    before do
      allow(Dor::Services::Client).to receive(:object).and_return(object_client)
      allow(LyberCore::WorkflowClientFactory).to receive(:build).and_return(workflow_client)

      # Workspace fixtures being used for staging.
      allow(Settings.sdr).to receive_messages(staging_root: 'spec/fixtures/workspace', local_workspace_root: workspace_root)
    end

    after do
      FileUtils.rm_rf(workspace_root)
    end

    context 'when not a DRO' do
      let(:object) { build(:collection, id: druid) }

      it 'skips the robot' do
        expect(perform.status).to eq('skipped')
        expect(perform.note).to eq('object is not an item')
      end
    end

    context 'when a DRO with no staging directory' do
      let(:druid) { 'druid:bb116zh0354' }

      it 'skips the robot' do
        expect(perform.status).to eq('skipped')
        expect(perform.note).to match(/no files in staging/)
      end
    end

    context 'when a DRO with files to be staged' do
      let(:delete_me_filepath) { "#{object_workspace_root}/delete_me.txt" }

      let(:object) do
        build(:dro, id: druid).new(
          structural: {
            contains: [{
              externalIdentifier: '222',
              type: Cocina::Models::FileSetType.file,
              label: 'my repository object',
              version: 1,
              structural: {
                contains: [
                  {
                    externalIdentifier: '222-1',
                    label: 'folder1PuSu/story1u.txt',
                    filename: 'folder1PuSu/story1u.txt',
                    type: Cocina::Models::ObjectType.file,
                    version: 1,
                    access: {},
                    size: 7888,
                    administrative: { publish: true, sdrPreserve: true, shelve: false },
                    hasMessageDigests: [{ type: 'md5', digest: '123' }]
                  }
                ]
              }
            }]
          }
        )
      end

      before do
        FileUtils.mkdir_p(object_workspace_root)
        File.write(delete_me_filepath, 'This file should be deleted ')
      end

      it 'completes the step' do
        expect { perform }.not_to raise_error

        expect(File.exist?("#{object_workspace_root}/content/folder1PuSu/story1u.txt")).to be true
        expect(File.exist?(delete_me_filepath)).to be false
      end
    end

    context 'when file already accessioned (and therefore missing)' do
      let(:object) do
        build(:dro, id: druid).new(
          structural: {
            contains: [{
              externalIdentifier: '222',
              type: Cocina::Models::FileSetType.file,
              label: 'my repository object',
              version: 1,
              structural: {
                contains: [
                  {
                    externalIdentifier: '222-1',
                    label: 'folder1PuSu/already_accessioned.txt',
                    filename: 'folder1PuSu/already_accessioned.txt',
                    type: Cocina::Models::ObjectType.file,
                    version: 1,
                    access: {},
                    size: 7888,
                    administrative: { publish: true, sdrPreserve: true, shelve: false },
                    hasMessageDigests: [{ type: 'md5', digest: '123' }]
                  }
                ]
              }
            }]
          }
        )
      end

      it 'raises' do
        expect { perform }.not_to raise_error
      end
    end

    context 'when file size mismatch' do
      let(:object) do
        build(:dro, id: druid).new(
          structural: {
            contains: [{
              externalIdentifier: '222',
              type: Cocina::Models::FileSetType.file,
              label: 'my repository object',
              version: 1,
              structural: {
                contains: [
                  {
                    externalIdentifier: '222-1',
                    label: 'folder1PuSu/story1u.txt',
                    filename: 'folder1PuSu/story1u.txt',
                    type: Cocina::Models::ObjectType.file,
                    version: 1,
                    access: {},
                    size: 1,
                    administrative: { publish: true, sdrPreserve: true, shelve: false },
                    hasMessageDigests: [{ type: 'md5', digest: '123' }]
                  }
                ]
              }
            }]
          }
        )
      end

      it 'raises' do
        expect { perform }.to raise_error(StandardError, /File incorrect size/)
      end
    end
  end
end
