# frozen_string_literal: true

require 'spec_helper'

describe Dor::TextExtraction::FileFetcher do
  let(:file_fetcher) { described_class.new(druid:, logger:) }

  let(:logger) { instance_double(Logger, warn: nil, info: nil, error: nil) }
  let(:druid) { 'druid:bb222cc3333' }
  let(:bare_druid) { 'bb222cc3333' }
  let(:objects_client) { instance_double(Preservation::Client::Objects) }
  let(:base_dir) { "tmp/#{bare_druid}" }

  let(:pres_client) { instance_double(Preservation::Client, objects: objects_client) }

  before do
    FileUtils.mkdir_p(base_dir)
    allow(Preservation::Client).to receive(:configure).and_return(pres_client)
    allow(file_fetcher).to receive(:sleep) # effectively make the sleep a no-op so that the test doesn't take so long due to retries and backoff
  end

  describe '#write_file_with_retries' do
    context 'when writing to disk' do
      let(:filename) { 'image111.tif' }
      let(:file_path) { File.join(base_dir, filename) }
      let(:location) { Pathname.new(file_path) }

      context 'when preservation is done' do
        before do
          allow(objects_client).to receive(:content) do |*args|
            filepath = args.first.fetch(:filepath)
            args.first.fetch(:on_data).call("Content for: #{filepath}")
          end
        end

        it 'writes the file' do
          file_fetcher.write_file_with_retries(filename:, location:)
          expect(Preservation::Client).to have_received(:configure)
          expect(logger).to have_received(:info).once
          expect(objects_client).to have_received(:content).once # success first time!

          expect(File.read(file_path)).to eq("Content for: #{filename}")
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
          file_fetcher.write_file_with_retries(filename:, location:)
          expect(Preservation::Client).to have_received(:configure)
          expect(logger).to have_received(:warn).twice

          expect(objects_client).to have_received(:content).exactly(3).times # 2 failures, 3rd time is the charm

          expect(File.read(file_path)).to eq("Content for: #{filename}")
        end

        context 'when retries are exhausted before the files show up on the preservation NFS mount' do
          before do
            allow(Honeybadger).to receive(:notify)

            allow(objects_client).to receive(:content) do
              raise Faraday::ResourceNotFound, 'druid not available yet'
            end
          end

          it 'returns false, sends to HB, and logs an error' do
            written = file_fetcher.write_file_with_retries(filename:, location:)
            expect(written).to be(false)

            context = { druid:, filename:, max_tries: 3, path: file_path }
            expect(logger).to have_received(:error).with("Exceeded max_tries attempting to fetch file: #{context}")
            expect(Honeybadger).to have_received(:notify).with('Exceeded max_tries attempting to fetch file', context:)
            expect(file_fetcher).to have_received(:sleep).with(8) # should have hit max backoff time of 2^3 seconds
          end
        end
      end
    end

    context 'when sending to S3' do
      let(:filename) { 'file1.mov' }
      let(:key) { File.join(bare_druid, filename) }
      let(:client) { instance_double(Aws::S3::Client) }
      let(:location) { Aws::S3::Object.new(bucket_name: 'bucket', key:, client:) }

      context 'when preservation is done' do
        before do
          allow(objects_client).to receive(:content) do |*args|
            filepath = args.first.fetch(:filepath)
            args.first.fetch(:on_data).call("Content for: #{filepath}")
          end
          allow(client).to receive_messages(create_multipart_upload: instance_double(Aws::S3::Types::CreateMultipartUploadOutput, upload_id: '123'),
                                            upload_part: instance_double(Aws::S3::Types::UploadPartOutput, etag: 'etag'))
          allow(client).to receive(:complete_multipart_upload)
        end

        it 'fetches files from perservation and sends to s3' do
          file_fetcher.write_file_with_retries(filename:, location:)
          expect(logger).to have_received(:info).once
          expect(objects_client).to have_received(:content).once
          expect(client).to have_received(:create_multipart_upload).once
          expect(client).to have_received(:upload_part).once
          expect(client).to have_received(:complete_multipart_upload).once
        end
      end
    end

    context 'when passing an invalid location' do
      let(:filename) { 'image111.tif' }
      let(:location) { {} } # not an Aws::S3::Object or an instance of Pathname or a string

      it 'raises an error' do
        expect { file_fetcher.write_file_with_retries(filename:, location:) }.to raise_error(RuntimeError, 'Unknown location type: Hash')
      end
    end
  end
end
