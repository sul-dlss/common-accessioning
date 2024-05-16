# frozen_string_literal: true

require 'spec_helper'

describe Robots::DorRepo::Ocr::FetchFiles do
  let(:robot) { described_class.new }
  let(:access) { { view: 'world' } }
  let(:druid) { 'druid:bb222cc3333' }
  let(:cocina_model) { build(:dro, id: druid).new(structural:, type: object_type, access:) }
  let(:object_type) { 'https://cocina.sul.stanford.edu/models/image' }
  let(:structural) do
    {
      contains: [
        {
          type: 'https://cocina.sul.stanford.edu/models/resources/image',
          externalIdentifier: 'bb111bb2222_1',
          label: 'Image 1',
          version: 1,
          structural: {
            contains: [
              {
                type: 'https://cocina.sul.stanford.edu/models/file',
                externalIdentifier: 'https://cocina.sul.stanford.edu/file/d30f48f9-1c11-4290-95a4-fea64e346db9',
                label: 'image111.tif',
                filename: 'image111.tif',
                size: 123,
                version: 1,
                hasMimeType: 'image/tiff',
                hasMessageDigests: [
                  {
                    type: 'md5',
                    digest: '42616f9e6c1b7e7b7a71b4fa0c5ef794'
                  }
                ],
                access: {
                  view: 'dark',
                  download: 'none',
                  controlledDigitalLending: false
                },
                administrative: {
                  publish: false,
                  sdrPreserve: true,
                  shelve: false
                }
              }
            ]
          }
        },
        {
          type: 'https://cocina.sul.stanford.edu/models/resources/image',
          externalIdentifier: 'bb111bb2222_2',
          label: 'Image 2',
          version: 1,
          structural: {
            contains: [
              {
                type: 'https://cocina.sul.stanford.edu/models/file',
                externalIdentifier: 'https://cocina.sul.stanford.edu/file/39a83c02-5d05-4c3d-bff1-080772cfdd99',
                label: 'image112.tif',
                filename: 'image112.tif',
                size: 123,
                version: 1,
                hasMimeType: 'image/tiff',
                hasMessageDigests: [
                  {
                    type: 'sha1',
                    digest: '5c9f6dc2ca4fd3329619b54a2c6f99a08c088444'
                  },
                  {
                    type: 'md5',
                    digest: 'ac440802bd590ce0899dafecc5a5ab1b'
                  }
                ],
                access: {
                  view: 'dark',
                  download: 'none',
                  controlledDigitalLending: false
                },
                administrative: {
                  publish: false,
                  sdrPreserve: true,
                  shelve: false
                }
              }
            ]
          }
        }
      ],
      hasMemberOrders: [],
      isMemberOf: []
    }
  end

  let(:dsa_object_client) do
    instance_double(Dor::Services::Client::Object, find: cocina_model, update: true)
  end

  let(:pres_client) do
    instance_double(Preservation::Client, objects: objects_client)
  end

  let(:objects_client) do
    instance_double(Preservation::Client::Objects)
  end

  let(:workflow_client) do
    instance_double(Dor::Workflow::Client, process: workflow_process, workflow_status: status)
  end

  let(:workflow_process) do
    instance_double(Dor::Workflow::Response::Process, lane_id:, context:)
  end

  let(:lane_id) { 'lane1' }
  let(:context) { { 'runOCR' => true } }
  let(:status) { 'waiting' }

  before do
    allow(Dor::Services::Client).to receive(:object).and_return(dsa_object_client)
    allow(Preservation::Client).to receive(:configure).and_return(pres_client)
    allow(LyberCore::WorkflowClientFactory).to receive(:build).and_return(workflow_client)
    allow(objects_client).to receive(:content) do |*args|
      filepath = args.first.fetch(:filepath)
      args.first.fetch(:on_data).call("Content for: #{filepath}")
    end
  end

  describe '#perform' do
    context 'with two image files' do
      before do
        test_perform(robot, druid)
      end

      it 'calls gets cocina from DSA' do
        expect(dsa_object_client).to have_received(:find)
      end

      it 'configures preservation client' do
        expect(Preservation::Client).to have_received(:configure)
      end

      it 'calls the workflow service to get the context' do
        expect(workflow_client).to have_received(:process)
      end

      it 'writes the two files' do
        expect(objects_client).to have_received(:content).twice

        file1 = File.join(Settings.sdr.abbyy.local_ticket_path, 'bb222cc3333', 'image111.tif')
        expect(File.read(file1)).to eq('Content for: image111.tif')

        file2 = File.join(Settings.sdr.abbyy.local_ticket_path, 'bb222cc3333', 'image112.tif')
        expect(File.read(file2)).to eq('Content for: image112.tif')
      end
    end
  end
end
