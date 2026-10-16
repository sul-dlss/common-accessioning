# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Accession::Stage do
  subject(:robot) { described_class.new }

  describe '.perform' do
    subject(:perform) { test_perform(robot, druid) }

    let(:druid) { 'druid:dd116zh0343' }
    let(:object_client) { instance_double(Dor::Services::Client::Object, find: object) }
    let(:object_workflow) { instance_double(Dor::Services::Client::ObjectWorkflow) }
    let(:assembly_root) { Dir.mktmpdir }
    let(:staging_root) { Dir.mktmpdir }
    let(:workspace_root) { Dir.mktmpdir }
    let(:assembly_pathname) { DruidTools::Druid.new(druid, assembly_root).pathname }
    let(:staging_pathname) { DruidTools::Druid.new(druid, staging_root).pathname }
    let(:workspace_pathname) { DruidTools::Druid.new(druid, workspace_root).pathname }
    let(:fixture_pathname) { DruidTools::Druid.new(druid, 'spec/fixtures/workspace').pathname }
    let(:staged_filepath) { 'content/folder1PuSu/story1u.txt' }
    let(:filename) { 'folder1PuSu/story1u.txt' }
    let(:file_size) { 7888 }

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
                  label: filename,
                  filename:,
                  type: Cocina::Models::ObjectType.file,
                  version: 1,
                  access: {},
                  size: file_size,
                  administrative: { publish: true, sdrPreserve: true, shelve: false },
                  hasMessageDigests: [{ type: 'md5', digest: '123' }]
                }
              ]
            }
          }]
        }
      )
    end

    def stage_fixture(pathname)
      pathname.parent.mkpath
      FileUtils.cp_r(fixture_pathname, pathname.parent)
    end

    before do
      allow(Dor::Services::Client).to receive(:object).and_return(object_client)
      allow(object_client).to receive(:workflow).and_return(object_workflow)
      allow(Settings.sdr).to receive_messages(assembly_root:, staging_root:, local_workspace_root: workspace_root)
    end

    after do
      FileUtils.rm_rf(assembly_root)
      FileUtils.rm_rf(staging_root)
      FileUtils.rm_rf(workspace_root)
    end

    context 'when not a DRO' do
      let(:object) { build(:collection, id: druid) }

      it 'skips the robot' do
        expect(perform.status).to eq('skipped')
        expect(perform.note).to eq('object is not an item')
      end
    end

    context 'when no staged content and no workspace' do
      it 'skips the robot' do
        expect(perform.status).to eq('skipped')
        expect(perform.note).to eq('no staged content')
      end
    end

    context 'when in the assembly root' do
      before { stage_fixture(assembly_pathname) }

      it 'moves the content to the workspace' do
        expect(perform.status).to eq('completed')
        expect(perform.note).to eq("moved from #{assembly_root}")

        expect(workspace_pathname.join(staged_filepath)).to exist
        expect(workspace_pathname).not_to be_symlink
        expect(assembly_pathname).not_to exist
      end
    end

    context 'when in the assembly root and the move crosses file systems' do
      before do
        stage_fixture(assembly_pathname)
        allow(File).to receive(:rename).and_raise(Errno::EXDEV)
      end

      it 'raises' do
        expect { perform }.to raise_error(Errno::EXDEV)
      end
    end

    context 'when retrying after a move' do
      before { stage_fixture(workspace_pathname) }

      it 'skips the robot and leaves the workspace' do
        expect(perform.status).to eq('skipped')
        expect(perform.note).to eq('no staged content')

        expect(workspace_pathname.join(staged_filepath)).to exist
      end
    end

    context 'when retrying after a move with a file size mismatch' do
      let(:file_size) { 1 }

      before { stage_fixture(workspace_pathname) }

      it 'raises' do
        expect { perform }.to raise_error(StandardError, /File incorrect size/)
      end
    end

    context 'when in the assembly root and the workspace exists' do
      before do
        stage_fixture(assembly_pathname)
        workspace_pathname.mkpath
      end

      it 'raises and leaves both' do
        expect { perform }.to raise_error(StandardError, /Staged content in both/)

        expect(assembly_pathname.join(staged_filepath)).to exist
        expect(workspace_pathname).to exist
      end
    end

    context 'when in the assembly root with a file size mismatch' do
      let(:file_size) { 1 }

      before { stage_fixture(assembly_pathname) }

      it 'raises' do
        expect { perform }.to raise_error(StandardError, /File incorrect size/)
      end
    end

    context 'when in the staging root' do
      let(:delete_me_pathname) { workspace_pathname.join('delete_me.txt') }

      before do
        stage_fixture(staging_pathname)
        workspace_pathname.mkpath
        File.write(delete_me_pathname, 'This file should be deleted')
      end

      it 'replaces the workspace with a copy and keeps staging' do
        expect(perform.status).to eq('completed')
        expect(perform.note).to eq("copied from #{staging_root}")

        expect(workspace_pathname.join(staged_filepath)).to exist
        expect(workspace_pathname).not_to be_symlink
        expect(delete_me_pathname).not_to exist
        expect(staging_pathname.join(staged_filepath)).to exist
      end
    end

    context 'when in the staging root with a file size mismatch' do
      let(:file_size) { 1 }

      before { stage_fixture(staging_pathname) }

      it 'raises' do
        expect { perform }.to raise_error(StandardError, /File incorrect size/)
      end
    end

    context 'when in the staging root and a file was already accessioned (and therefore missing)' do
      let(:filename) { 'folder1PuSu/already_accessioned.txt' }

      before { stage_fixture(staging_pathname) }

      it 'completes the step' do
        expect(perform.status).to eq('completed')
      end
    end

    context 'when in both roots' do
      before do
        stage_fixture(assembly_pathname)
        stage_fixture(staging_pathname)
      end

      it 'raises' do
        expect { perform }.to raise_error(Dor::StagedContent::MultipleRootsError)
      end
    end

    context 'when the workspace is a legacy symlink to the assembly root' do
      before do
        stage_fixture(assembly_pathname)
        workspace_pathname.parent.mkpath
        workspace_pathname.make_symlink(assembly_pathname)
      end

      it 'skips the robot and leaves the symlink' do
        expect(perform.status).to eq('skipped')
        expect(perform.note).to eq('workspace is a legacy symlink')

        expect(workspace_pathname).to be_symlink
        expect(assembly_pathname.join(staged_filepath)).to exist
      end
    end

    context 'when the workspace is a legacy symlink to the staging root' do
      before do
        stage_fixture(staging_pathname)
        workspace_pathname.parent.mkpath
        workspace_pathname.make_symlink(staging_pathname)
      end

      it 'skips the robot and leaves the symlink' do
        expect(perform.status).to eq('skipped')
        expect(perform.note).to eq('workspace is a legacy symlink')

        expect(workspace_pathname).to be_symlink
        expect(staging_pathname.join(staged_filepath)).to exist
      end
    end

    context 'when the workspace is a legacy symlink with a file size mismatch' do
      let(:file_size) { 1 }

      before do
        stage_fixture(staging_pathname)
        workspace_pathname.parent.mkpath
        workspace_pathname.make_symlink(staging_pathname)
      end

      it 'raises' do
        expect { perform }.to raise_error(StandardError, /File incorrect size/)
      end
    end

    context 'when the workspace is a dangling symlink' do
      before do
        workspace_pathname.parent.mkpath
        workspace_pathname.make_symlink(assembly_pathname)
      end

      it 'raises' do
        expect { perform }.to raise_error(StandardError, /dangling symlink/)
      end
    end
  end
end
