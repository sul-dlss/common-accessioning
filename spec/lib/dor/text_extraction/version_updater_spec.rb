# frozen_string_literal: true

describe Dor::TextExtraction::VersionUpdater do
  subject(:updater) { described_class.new(druid:, object_client:, description:, max_tries: 3) }

  let(:druid) { 'druid:bb222cc3333' }
  let(:description) { 'Starting OCR' }

  let(:object) { build(:dro, id: druid) }
  let(:workspace_client) { instance_double(Dor::Services::Client::Workspace) }
  let(:version_client) do
    instance_double(Dor::Services::Client::ObjectVersion,
                    status: instance_double(Dor::Services::Client::ObjectVersion::VersionStatus, open?: version_open))
  end
  let(:object_client) do
    instance_double(Dor::Services::Client::Object, version: version_client, workspace: workspace_client, find: object)
  end

  before do
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    allow(version_client).to receive(:open)
  end

  describe '.open' do
    let(:version_open) { false }

    before do
      described_class.open(druid:, object_client:, description:)
      allow(version_client).to receive(:open)
    end

    it 'opens the object' do
      expect(version_client).to have_received(:open)
    end
  end

  describe '#open_object' do
    context 'when object is already opened' do
      let(:version_open) { true }

      it 'does not call the object client to open the version' do
        updater.open_object
        expect(version_client).not_to have_received(:open)
      end
    end

    context 'when object is not opened' do
      let(:version_open) { false }

      context 'when open version succeeds' do
        it 'calls the object client to open the version' do
          updater.open_object
          expect(version_client).to have_received(:open).with(description:)
        end
      end

      context 'when open version fails' do
        before { allow(Honeybadger).to receive(:notify) }

        context 'when open version fails twice and then succeeds' do
          before do
            count = 0
            allow(version_client).to receive(:open) do |*_args|
              count += 1
              raise Dor::Services::Client::UnexpectedResponse.new(response: 'nope') unless count > 2

              true
            end
          end

          it 'retries the first two errors, then calls open again and logs to honeybadger' do
            expect { updater.open_object }.not_to raise_error
            expect(version_client).to have_received(:open).thrice # shakespeare coding (first two times fail, third time succeeds)
            expect(Honeybadger).to have_received(:notify).twice # two calls to HB for the first two failures
          end
        end

        context 'when open version fails and exceeds maximum tries' do
          before { allow(version_client).to receive(:open).and_raise(Dor::Services::Client::UnexpectedResponse.new(response: 'nope')) }

          it 'logs to honeybadger and then raises the error' do
            expect { updater.open_object }.to raise_error(Dor::Services::Client::UnexpectedResponse)
            expect(version_client).to have_received(:open).thrice # shakespeare coding (all three times fail)
            expect(Honeybadger).to have_received(:notify).twice # two calls to HB for the first two failures
          end
        end
      end
    end
  end
end
