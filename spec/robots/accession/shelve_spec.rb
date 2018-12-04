# frozen_string_literal: true

require 'spec_helper'

require File.expand_path(File.dirname(__FILE__) + '/../../../robots/accession/shelve')

describe Robots::DorRepo::Accession::Shelve do
  let(:druid) { 'druid:oo000oo0001' }

  it 'includes behavior from LyberCore::Robot' do
    robot = Robots::DorRepo::Accession::Shelve.new
    expect(robot.methods).to include(:work)
  end

  describe '#perform' do
    let(:robot) { described_class.new }
    subject(:perform) { robot.perform(druid) }
    before do
      allow(Dor::Config.workflow).to receive(:client).and_return(double(get_workflow_status: 'fail'))
      allow(Dor::Config.workflow).to receive(:url).and_return('http://workflow.sdr/')
      expect(Dor).to receive(:find).with(druid).and_return(object)
    end
    context 'when using an Item' do
      let(:object) { Dor::Item.new(pid: druid) }

      it 'calls Shelve' do
        expect(Dor::Shelve).to receive(:push).with(object)
        perform
      end
    end

    context 'when using an APO' do
      let(:object) { Dor::AdminPolicyObject.new(pid: druid) }

      it 'does not call Shelve' do
        expect(Dor::Shelve).not_to receive(:push)
        perform
      end
    end
  end
end
