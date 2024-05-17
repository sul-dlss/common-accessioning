# frozen_string_literal: true

require 'spec_helper'

describe Robots::DorRepo::Ocr::XmlTicketCreate do
  subject(:perform) { test_perform(robot, druid) }

  include_context 'with abbyy dir'

  let(:bare_druid) { 'bb222cc3333' }
  let(:druid) { "druid:#{bare_druid}" }
  let(:robot) { described_class.new }
  let(:ocr) { instance_double(Dor::TextExtraction::Ocr) }
  let(:dsa_object_client) do
    instance_double(Dor::Services::Client::Object, find: cocina_model, update: true)
  end
  let(:cocina_model) { build(:dro, id: druid).new(structural: {}, type: object_type, access: { view: 'world' }) }
  let(:object_type) { 'https://cocina.sul.stanford.edu/models/image' }
  let(:workflow_context) { { 'runOCR' => true } }
  let(:workflow) { instance_double(LyberCore::Workflow, context: workflow_context) }
  let(:fixture_path) { File.join(File.absolute_path('spec/fixtures/ocr'), "#{bare_druid}_abbyy_ticket.xml") }

  before do
    allow(Settings.sdr.abbyy).to receive_messages(
      local_result_path: abbyy_result_xml_path,
      local_exception_path: abbyy_exceptions_path,
      local_ticket_path: abbyy_xml_ticket_path
    )
    allow(Dor::TextExtraction::Ocr).to receive(:new).and_return(ocr)
    allow(ocr).to receive(:filenames_to_ocr).and_return(['filename1.jp2', 'filename2.jp2', 'filename3.jp2'])
    allow(Dor::Services::Client).to receive(:object).and_return(dsa_object_client)
    allow(LyberCore::Workflow).to receive(:new).and_return(workflow)
  end

  it 'creates the ABBYY XML ticket and writes it to the correct folder' do
    perform
    xml_file = File.join(abbyy_xml_ticket_path, "#{bare_druid}.xml")
    expect(File.exist?(xml_file)).to be true
    expect(File.read(xml_file)).to be_equivalent_to File.read(fixture_path)
  end
end
