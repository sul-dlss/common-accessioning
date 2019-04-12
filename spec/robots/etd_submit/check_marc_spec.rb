# frozen_string_literal: true

# require 'spec_helper'
# require 'etd_submit/check_marc'

# describe Robots::DorRepo::EtdSubmit::CheckMarc do
#   before do
#     @mock_workflow = double('workflow')
#     @mock_queue = double('queue')
#     @mock_dor_service = double('DorService')
#   end

#   it 'processes a batch of druids from a list of files' do
#     list_file = 'spec/fixtures/list.txt'

#     LyberCore::Robots::Workflow.should_receive(:new).and_return(@mock_workflow)
#     @mock_workflow.should_receive(:queue).with('check-marc').and_return(@mock_queue)
#     @mock_queue.should_receive(:enqueue_identifiers).with('druid', ["druid:mj151qw9093"])
#     EtdSubmit::CheckMarc.should_receive(:process_queue)
#     EtdSubmit::CheckMarc.process_queue(list_file)
#   end

#   it 'processes a batch of druids by getting workflow status from DOR' do
#     LyberCore::Robots::Workflow.should_receive(:new).and_return(@mock_workflow)
#     @mock_workflow.should_receive(:queue).with('check-marc').and_return(@mock_queue)
#     @mock_queue.should_receive(:enqueue_workstep_waiting)
#     EtdSubmit::CheckMarc.should_receive(:process_queue)
#     EtdSubmit::CheckMarc.process_batch()
#   end
# end

# describe "check marc record"  do
#    before(:all) do
#      @symphony_output1 = IO.read('spec/fixtures/druid_mj151qw9093/symphony_output1.xml')
#    end
#
#    it "should check symphony for current location" do
#     druid="druid:mj151qw9093"
#     flexkey = "dormj151qw9093"
#
#     identity_string =  "<?xml version=\"1.0\"?>\n<identityMetadata>\n  <catkey>8379324</catkey>\n</identityMetadata>\n"
#     identity_metadata = Nokogiri::XML('<identityMetadata/>')
#
#     DorService.should_receive(:query_symphony).with(flexkey).and_return(@symphony_output1)
#     DorService.should_receive(:add_datastream_unless_exists).with(druid,'identityMetadata','identityMetadata', identity_metadata.to_xml ).and_return(nil)
#     DorService.should_receive(:get_datastream).with(druid, 'identityMetadata').and_return(identity_metadata.to_s)
#     DorService.should_receive(:update_datastream).with(druid, 'identityMetadata', identity_string)
#
#     EtdSubmit::CheckMarc.check_marc(druid)
#    end
# end
