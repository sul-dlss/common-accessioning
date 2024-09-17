# frozen_string_literal: true

require 'spec_helper'

describe Robots::DorRepo::SpeechToText::UpdateCocina do
  include_context 'with workspace dir'

  let(:robot) { described_class.new }
  let(:bare_druid) { 'bb222cc3333' }
  let(:druid) { "druid:#{bare_druid}" }

  # DruidTools needs to return the workspace_dir set up by "with workspace dir" context
  let(:druid_tools) do
    instance_double(DruidTools::Druid, id: bare_druid, content_dir: workspace_content_dir)
  end

  let(:dsa_object_client) do
    instance_double(Dor::Services::Client::Object, find: cocina_model, update: true)
  end

  # set up a Cocina object with one audio file in it
  let(:cocina_model) { build(:dro, id: druid).new(structural:, type: object_type) }
  let(:object_type) { 'https://cocina.sul.stanford.edu/models/media' }
  let(:structural) do
    {
      contains: [
        {
          type: 'https://cocina.sul.stanford.edu/models/resources/file',
          externalIdentifier: "#{bare_druid}_1",
          label: 'Audio 1',
          version: 1,
          structural: {
            contains: [
              {
                type: Cocina::Models::ObjectType.file,
                externalIdentifier: "#{druid}_1",
                label: 'file1.wav',
                filename: 'file1.wav',
                size: 123,
                version: 1,
                hasMimeType: 'audio/x-wav'
              }
            ]
          }
        }
      ]
    }
  end

  before do
    allow(Dor::Services::Client).to receive(:object).and_return(dsa_object_client)

    allow(DruidTools::Druid).to receive(:new).and_return(druid_tools)
  end

  context 'with an xml file' do
    # setup a fake caption XML file in the workspace directory which matches the name of the audio file in the Cocina
    before { create_xml_file('file1.xml') }

    it 'runs the update cocina robot and sets the transcription role' do
      new_cocina = test_perform(robot, druid)
      new_file = new_cocina.structural.contains[0].structural.contains[1]
      expect(new_file.filename).to eq 'file1.xml'
      expect(new_file.use).to eq 'transcription'
    end
  end

  context 'with a txt file' do
    # setup a fake caption txt file in the workspace directory which matches the name of the audio file in the Cocina
    before { create_txt_file('file1.txt') }

    it 'runs the update cocina robot and does not set the transcription role' do
      new_cocina = test_perform(robot, druid)
      new_file = new_cocina.structural.contains[0].structural.contains[1]
      expect(new_file.filename).to eq 'file1.txt'
      expect(new_file.use).to be_nil
    end
  end
end
