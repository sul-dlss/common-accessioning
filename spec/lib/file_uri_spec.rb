# frozen_string_literal: true

RSpec.describe FileUri do
  let(:workspace) { File.absolute_path('spec/fixtures/workspace') }
  let(:druid) { 'druid:dd116zh0343' }
  let(:root) { File.absolute_path(Settings.sdr.local_workspace_root) }

  let(:content_dir) do
    workspace = DruidTools::Druid.new(druid, root)
    workspace.content_dir(false)
  end

  before do
    # For File URIs, need to use absolute paths
    allow(Settings.sdr).to receive(:local_workspace_root).and_return(workspace)
  end

  describe '.to_s' do
    subject { described_class.new(filename).to_s }

    context 'with a sub folder' do
      let(:filename) { "#{content_dir}/folder1PuSu/folder2/story1u.txt" }

      it { is_expected.to eq "file://#{root}/dd/116/zh/0343/dd116zh0343/content/folder1PuSu/folder2/story1u.txt" }
    end

    context 'with a space' do
      let(:filename) { "#{content_dir}/folder with space/file with space.txt" }

      it { is_expected.to eq "file://#{root}/dd/116/zh/0343/dd116zh0343/content/folder%20with%20space/file%20with%20space.txt" }
    end

    context 'with a diacritic' do
      let(:filename) { "#{content_dir}/Garges-lès-Gonesse.docx" }

      it { is_expected.to eq "file://#{root}/dd/116/zh/0343/dd116zh0343/content/Garges-l%C3%A8s-Gonesse.docx" }
    end
  end
end
