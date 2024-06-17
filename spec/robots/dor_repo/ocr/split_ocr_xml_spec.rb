# frozen_string_literal: true

require 'spec_helper'

describe Robots::DorRepo::Ocr::SplitOcrXml do
  subject(:perform) { test_perform(robot, druid) }

  include_context 'with abbyy dir'

  let(:druid) { 'druid:bb222cc3333' }
  let(:bare_druid) { 'bb222cc3333' }
  let(:robot) { described_class.new }
  let(:alto_path) { File.join(File.absolute_path('spec/fixtures/ocr'), "#{bare_druid}_abbyy_alto.xml") }
  let(:contents) { File.read(alto_path) }
  let(:output_path) { File.join(abbyy_output_path, bare_druid) }

  let(:object) { build(:dro, id: druid) }
  let(:workspace_client) { instance_double(Dor::Services::Client::Workspace) }
  let(:version_client) do
    instance_double(Dor::Services::Client::ObjectVersion, open: true,
                                                          status: instance_double(Dor::Services::Client::ObjectVersion::VersionStatus, open?: false))
  end
  let(:object_client) do
    instance_double(Dor::Services::Client::Object, version: version_client, workspace: workspace_client, find: object)
  end

  before do
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    allow(Settings.sdr.abbyy).to receive_messages(
      local_output_path: abbyy_output_path
    )
  end

  it 'creates 3 xml files' do
    copy_abbyy_alto(output_path:, contents:, druid: bare_druid)
    test_perform(robot, druid)
    created_files = %w[bb222cc3333_00_0001.xml bb222cc3333_00_0002.xml bb222cc3333_00_0003.xml]
    expect(created_files.all? { |file| File.exist?(File.join(output_path, file)) }).to be true
  end

  it 'there is no file' do
    expect { test_perform(robot, druid) }.to raise_error(RuntimeError)
  end
end
