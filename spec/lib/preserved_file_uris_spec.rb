# frozen_string_literal: true

RSpec.describe PreservedFileUris do
  let(:workspace) { File.absolute_path('spec/fixtures/workspace') }
  let(:druid) { 'druid:dd116zh0343' }
  let(:root) { File.absolute_path(Settings.sdr.local_workspace_root) }
  let(:object) do
    Cocina::Models::DRO.new(externalIdentifier: druid,
                            type: Cocina::Models::ObjectType.object,
                            label: 'my repository object',
                            version: 1,
                            description: {
                              title: [{ value: 'my repository object' }],
                              purl: "https://purl.stanford.edu/#{druid.delete_prefix('druid:')}"
                            },
                            access: {},
                            administrative: { hasAdminPolicy: 'druid:xx999xx9999' },
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
                                      label: filename1,
                                      filename: filename1,
                                      type: Cocina::Models::ObjectType.file,
                                      version: 1,
                                      access: {},
                                      administrative: { publish: true, sdrPreserve: true, shelve: true },
                                      hasMessageDigests: []
                                    },
                                    {
                                      externalIdentifier: '222-2',
                                      label: 'not-this.pdf',
                                      filename: 'not-this.pdf',
                                      type: Cocina::Models::ObjectType.file,
                                      version: 1,
                                      access: {},
                                      administrative: { publish: true, sdrPreserve: false, shelve: true },
                                      hasMessageDigests: []
                                    },
                                    {
                                      externalIdentifier: '222-1',
                                      label: filename2,
                                      filename: filename2,
                                      type: Cocina::Models::ObjectType.file,
                                      version: 1,
                                      access: {},
                                      administrative: { publish: true, sdrPreserve: true, shelve: true },
                                      hasMessageDigests: []
                                    }
                                  ]
                                }
                              }]
                            },
                            identification: {})
  end

  before do
    # For File URIs, need to use absolute paths
    allow(Settings.sdr).to receive(:local_workspace_root).and_return(workspace)
  end

  describe '.uris' do
    subject { described_class.new(druid, object).uris }

    let(:prefix) { "file://#{root}/dd/116/zh/0343/dd116zh0343/content/" }

    let(:filename1) { 'folder1PuSu/story1u.txt' }
    let(:filename2) { 'folder1PuSu/story2u.txt' }

    it { is_expected.to eq ["#{prefix}#{filename1}", "#{prefix}#{filename2}"] }
  end

  describe '.filepaths' do
    subject { described_class.new(druid, object).filepaths }

    let(:filename1) { 'folder1PuSu/story1u.txt' }
    let(:filename2) { 'folder1PuSu/story2u.txt' }
    let(:prefix) { "#{root}/dd/116/zh/0343/dd116zh0343/content/" }

    it { is_expected.to eq ["#{prefix}#{filename1}", "#{prefix}#{filename2}"] }
  end
end
