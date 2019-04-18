# frozen_string_literal: true

require 'spec_helper'
require 'etd_submit/catalog_status'

# describe Robots::DorRepo::EtdSubmit::CatalogStatus do
#   before do
#     @mock_workflow = double('workflow')
#     @mock_queue = double('queue')
#     @mock_dor_service = double('DorService')
#   end

#   it 'processes a batch of druids from a list of files' do
#     list_file = 'spec/fixtures/list.txt'

#     LyberCore::Workflow.should_receive(:new).and_return(@mock_workflow)
#     @mock_workflow.should_receive(:queue).with('catalog-status').and_return(@mock_queue)
#     @mock_queue.should_receive(:enqueue_identifiers).with('druid', ['druid:mj151qw9093'])
#     EtdSubmit::CatalogStatus.should_receive(:process_queue)
#     EtdSubmit::CatalogStatus.process_batch(list_file)
#   end

#   it 'processes a batch of druids by getting workflow status from DOR' do
#     LyberCore::Workflow.should_receive(:new).and_return(@mock_workflow)
#     @mock_workflow.should_receive(:queue).with('catalog-status').and_return(@mock_queue)
#     @mock_queue.should_receive(:enqueue_workstep_waiting)
#     EtdSubmit::CatalogStatus.should_receive(:process_queue)
#     EtdSubmit::CatalogStatus.process_batch
#   end
# end

# describe 'should return true if current_location == home_location' do
#   before(:all) do
#     @symphony_output1 = IO.read('spec/fixtures/druid_mj151qw9093/symphony_output1.xml')
#     @symphony_output2 = IO.read('spec/fixtures/druid_mj151qw9093/symphony_output2.xml')
#     @workflow = IO.read('spec/fixtures/druid_mj151qw9093/etdAccessionWF.xml')
#     @workflow_shadow = IO.read('spec/fixtures/druid_mj151qw9093/etdAccessionWF_shadow.xml')
#     @druid = 'druid:mj151qw9093'
#     @flexkey = 'dormj151qw9093'
#   end

#   it 'checks symphony for the status of the record' do
#     DorService.should_receive(:query_symphony).with(@flexkey).and_return(@symphony_output2)
#     DorService.should_receive(:get_workflow_xml).with(@druid, 'etdAccessionWF').and_return(@workflow)

#     catalog_check = EtdSubmit::CatalogStatus.process_item(@druid)
#     catalog_check.should be true
#   end

#   it 'returns false if current_location != home_location, but update the workflow if @status != current_location' do
#     current_location = 'SHADOW'
#     DorService.should_receive(:query_symphony).with(@flexkey).and_return(@symphony_output1)
#     DorService.should_receive(:get_workflow_xml).with(@druid, 'etdAccessionWF').and_return(@workflow)
#     DorService.should_receive(:updateWorkflowStatus).with(@druid, 'etdAccessionWF', 'catalog-status', current_location, 0, 'inprocess')

#     catalog_check = EtdSubmit::CatalogStatus.check_status(@druid)
#     catalog_check.should be false
#   end

#   it 'returns false if current_location != home_location, but not update the workflow if @status = current_location' do
#     current_location = 'SHADOW'
#     DorService.should_receive(:query_symphony).with(@flexkey).and_return(@symphony_output1)
#     DorService.should_receive(:get_workflow_xml).with(@druid, 'etdAccessionWF').and_return(@workflow_shadow)
#     DorService.should_not_receive(:updateWorkflowStatus).with(@druid, 'etdAccessionWF', 'catalog-status', current_location, 0, 'inprocess')

#     catalog_check = EtdSubmit::CatalogStatus.check_status(@druid)
#     catalog_check.should be false
#   end
# end
