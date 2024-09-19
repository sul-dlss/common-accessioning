# frozen_string_literal: true

require 'spec_helper'

describe Dor::TextExtraction::FileFetcher do
  let(:file_fetcher) { described_class.new(druid:, logger:) }

  let(:logger) { instance_double(Logger, warn: nil, info: nil, error: nil) }
  let(:druid) { 'druid:bb222cc3333' }
  let(:objects_client) { instance_double(Preservation::Client::Objects) }

  let(:pres_client) do
    instance_double(Preservation::Client, objects: objects_client)
  end

  before do
    allow(Preservation::Client).to receive(:configure).and_return(pres_client)
    allow(file_fetcher).to receive(:sleep) # effectively make the sleep a no-op so that the test doesn't take so long due to retries and backoff
  end

  describe '#write_file_with_retries' do
    context 'when writing to disk' do
      context 'when preservation is done' do
        before do
          allow(objects_client).to receive(:content) do |*args|
            filepath = args.first.fetch(:filepath)
            args.first.fetch(:on_data).call("Content for: #{filepath}")
          end
        end

        it 'writes the file' do
          file_fetcher.write_file_with_retries(filename: 'image111.tif', path: Pathname.new('/tmp/image111.tif'))
          expect(Preservation::Client).to have_received(:configure)
          expect(logger).to have_received(:info).once
          expect(objects_client).to have_received(:content).once # success first time!

          file1 = File.join(Settings.sdr.abbyy.local_ticket_path, 'bb222cc3333', 'image111.tif')
          expect(File.read(file1)).to eq('Content for: image111.tif')
        end
      end

      context 'when preservation is still processing' do
        before do
          count = 0
          allow(objects_client).to receive(:content) do |*args|
            count += 1
            raise Faraday::ResourceNotFound, 'druid not available yet' unless count > 2

            filepath = args.first.fetch(:filepath)
            args.first.fetch(:on_data).call("Content for: #{filepath}")
          end
        end

        it 'writes the file and warns' do
          file_fetcher.write_file_with_retries(filename: 'image111.tif', path: Pathname.new('/tmp/image111.tif'))
          expect(Preservation::Client).to have_received(:configure)
          expect(logger).to have_received(:warn).twice

          expect(objects_client).to have_received(:content).exactly(3).times # 2 failures, 3rd time is the charm

          file1 = File.join(Settings.sdr.abbyy.local_ticket_path, 'bb222cc3333', 'image111.tif')
          expect(File.read(file1)).to eq('Content for: image111.tif')
        end

        context 'when retries are exhausted before the files show up on the preservation NFS mount' do
          before do
            allow(Honeybadger).to receive(:notify)

            allow(objects_client).to receive(:content) do
              raise Faraday::ResourceNotFound, 'druid not available yet'
            end
          end

          it 'returns false, sends to HB, and logs an error' do
            written = file_fetcher.write_file_with_retries(filename: 'image111.tif', path: Pathname.new('/tmp/image111.tif'))
            expect(written).to be(false)

            context = { druid:, filename: 'image111.tif', path: '/tmp/image111.tif', cloud_endpoint: nil, max_tries: 3 }
            expect(logger).to have_received(:error).with("Exceeded max_tries attempting to fetch file: #{context}")
            expect(Honeybadger).to have_received(:notify).with('Exceeded max_tries attempting to fetch file', context:)
            expect(file_fetcher).to have_received(:sleep).with(8) # should have hit max backoff time of 2^3 seconds
          end
        end
      end
    end

    context 'when sending to cloud endpoint' do
      before do
        allow(objects_client).to receive(:content) do |*args|
          filepath = args.first.fetch(:filepath)
          args.first.fetch(:on_data).call("Content for: #{filepath}")
        end
      end

      it 'fetches files from perservation and sends to cloud' do
        # TODO: add in actual expectations here when the method is implemented
        file_fetcher.write_file_with_retries(filename: 'file1.mov', cloud_endpoint: 's3://some-bucket/file1.mov')
        expect(logger).to have_received(:info).once
        expect(objects_client).to have_received(:content).once
        expect(Preservation::Client).to have_received(:configure)
      end
    end
  end
end
