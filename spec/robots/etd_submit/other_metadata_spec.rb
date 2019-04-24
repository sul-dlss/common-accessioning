# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::EtdSubmit::OtherMetadata do
  subject(:robot) { described_class.new }

  describe '#perform' do
    let(:druid) { 'druid:mj151qw9093' }
    let(:object) { Etd.new(pid: druid) }
    let(:druid_tools) { instance_double(DruidTools::Druid, content_dir: '/foo/bar') }
    let(:status) { instance_double(Process::Status, exitstatus: 0) }

    before do
      allow(Etd).to receive(:find).and_return(object)
      allow(object).to receive(:populate_datastream)
      allow(DruidTools::Druid).to receive(:new).and_return(druid_tools)
      allow(robot).to receive(:systemu).and_return([status, nil, nil])
      allow(File).to receive(:exist?).with('/foo/bar').and_return(true)
    end

    it 'invokes Dor::Services::Client with druid and workflow name' do
      robot.perform(druid)
      # expect(mock_workflow_instance).to have_received(:create).with(wf_name: 'accessionWF')
    end
  end
end
