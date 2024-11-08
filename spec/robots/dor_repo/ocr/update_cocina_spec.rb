# frozen_string_literal: true

require 'spec_helper'

describe Robots::DorRepo::Ocr::UpdateCocina do
  include_context 'with abbyy dir'
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

  # set up a Cocina object with one image in it
  let(:cocina_model) { build(:dro, id: druid).new(structural:, type: object_type) }
  let(:object_type) { 'https://cocina.sul.stanford.edu/models/image' }
  let(:structural) do
    {
      contains: [
        {
          type: 'https://cocina.sul.stanford.edu/models/resources/image',
          externalIdentifier: "#{bare_druid}_1",
          label: 'Image 1',
          version: 1,
          structural: {
            contains: [
              {
                type: Cocina::Models::ObjectType.file,
                externalIdentifier: "#{druid}_1",
                label: 'image1.tif',
                filename: 'image1.tif',
                size: 123,
                version: 1,
                hasMimeType: 'image/tiff'
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
    # setup a fake OCR XML file in the workspace directory which matches the name of the image file in the Cocina
    before { create_ocr_file('image1.xml') }

    it 'runs the update cocina robot and sets the transcription role' do
      new_cocina = test_perform(robot, druid)
      new_file = new_cocina.structural.contains[0].structural.contains[1]
      expect(new_file.filename).to eq 'image1.xml'
      expect(new_file.use).to eq 'transcription'
    end
  end

  context 'with a txt file' do
    # setup a fake OCR txt file in the workspace directory which matches the name of the image file in the Cocina
    before { create_ocr_file('image1.txt') }

    it 'runs the update cocina robot and does not set the transcription role' do
      new_cocina = test_perform(robot, druid)
      new_file = new_cocina.structural.contains[0].structural.contains[1]
      expect(new_file.filename).to eq 'image1.txt'
      expect(new_file.use).to be_nil
    end
  end
end
