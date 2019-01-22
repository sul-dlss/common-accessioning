# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'

RSpec.describe Robots::DorRepo::EtdSubmit::SubmitMarc do
  describe 'Exporting MARC' do
    def setup
      @robot = described_class.new
      @mock_workitem = double('submit_marc_workitem')
      allow(@mock_workitem).to receive(:druid).and_return('druid:cd950rh5120')
    end

    def cleanup
      mock_workitem = double('populate_metadata_workitem')
      allow(mock_workitem).to receive(:druid).and_return('druid:jc837rq9922')

      # Make sure we're starting with a blank object
      obj = ActiveFedora::Base.load_instance(mock_workitem.druid)
      obj&.delete if obj.persisted?
    end

    describe 'basic behavior' do
      it 'can be created' do
        r = described_class.new
        expect(r).to be_instance_of(described_class)
      end

      it "creates a tmp directory in ROBOT_ROOT if it doesn't exist" do
        expect(File).to receive(:exist?).with(ROBOT_ROOT + '/tmp').and_return(false)
        expect(FileUtils).to receive(:mkdir).with(ROBOT_ROOT + '/tmp')

        described_class.new
      end
    end
  end
end
