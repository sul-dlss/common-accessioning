# frozen_string_literal: true

RSpec.describe FileUris do
  let(:workspace) { File.absolute_path('spec/fixtures/workspace') }
  let(:druid) { 'druid:dd116zh0343' }
  let(:root) { File.absolute_path(Settings.sdr.local_workspace_root) }
  let(:object) do
    Cocina::Models::DRO.new(externalIdentifier: druid,
                            type: Cocina::Models::Vocab.object,
                            label: 'my repository object',
                            version: 1,
                            access: {},
                            structural: {
                              contains: [{
                                externalIdentifier: '222',
                                type: Cocina::Models::Vocab.fileset,
                                label: 'my repository object',
                                version: 1,
                                structural: {
                                  contains: [
                                    {
                                      externalIdentifier: '222-1',
                                      label: filename,
                                      type: Cocina::Models::Vocab.file,
                                      version: 1,
                                      access: {},
                                      administrative: { sdrPreserve: true, shelve: true },
                                      hasMessageDigests: []
                                    }
                                  ]
                                }
                              }]
                            })
  end

  before do
    # For File URIs, need to use absolute paths
    allow(Settings.sdr).to receive(:local_workspace_root).and_return(workspace)
  end

  describe '.uris' do
    subject { described_class.new(druid, object).uris }

    context 'with a sub folder' do
      let(:filename) { 'folder1PuSu/story1u.txt' }

      it { is_expected.to eq ["file://#{root}/dd/116/zh/0343/dd116zh0343/content/folder1PuSu/story1u.txt"] }
    end

    context 'with a space' do
      let(:filename) { 'file with space.txt' }

      it { is_expected.to eq ["file://#{root}/dd/116/zh/0343/dd116zh0343/content/file%20with%20space.txt"] }
    end

    context 'with a diacritic' do
      let(:filename) { 'Garges-lès-Gonesse.docx' }

      it { is_expected.to eq ["file://#{root}/dd/116/zh/0343/dd116zh0343/content/Garges-l%C3%A8s-Gonesse.docx"] }
    end
  end

  describe '.filepaths' do
    subject { described_class.new(druid, object).filepaths }

    let(:filename) { 'folder1PuSu/story1u.txt' }

    it { is_expected.to eq ["#{root}/dd/116/zh/0343/dd116zh0343/content/folder1PuSu/story1u.txt"] }
  end
end
