# frozen_string_literal: true

describe Dor::TextExtraction::SqsWatcher do
  subject(:sqs_watcher) { described_class.new(queue_url:, role_arn:, logger:, visibility_timeout:) }

  let(:queue_url) { Settings.aws.speech_to_text.sqs_done_queue_url }
  let(:region) { Settings.aws.region }
  let(:access_key_id) { Settings.aws.access_key_id }
  let(:secret_access_key) { Settings.aws.secret_access_key }
  let(:role_arn) { Settings.aws.speech_to_text.role_arn }
  let(:logger) { instance_double(Logger, info: nil, error: nil) }
  let(:visibility_timeout) { nil }
  let(:aws_provider) { instance_double(Dor::TextExtraction::AwsProvider, sqs: instance_double(Aws::SQS::Client)) }
  let(:aws_provider_opts) do
    { region:, access_key_id:, secret_access_key:, role_arn: }
  end
  let(:poller) { instance_double(Aws::SQS::QueuePoller) }

  let(:sqs_msg_hash) do
    { 'payload_field' => 'payload_value' }
  end
  let(:sqs_msg_body) { sqs_msg_hash.to_json }
  let(:sqs_msg) { instance_double(Aws::SQS::Types::Message, body: sqs_msg_body) }

  let(:message_handler) { instance_double(Dor::TextExtraction::SpeechToTextCreateDoneHandler, process_done_message: nil) }

  before do
    allow(Honeybadger).to receive(:notify)
    allow(Dor::TextExtraction::AwsProvider).to receive(:new).with(aws_provider_opts).and_return(aws_provider)
    allow(Aws::SQS::QueuePoller).to receive(:new).with(queue_url, { client: aws_provider.sqs }).and_return(poller)
    # NOTE: This is a somewhat unrealistically simplified mocking of QueuePoller#poll,
    # as the real invocation of that method in this codebase should cause it to run indefinitely,
    # polling for messages and invoking its block whenever one is received. But this mock instead
    # executes the block once.
    # TODO: there is a ticket for investigating localstack for more realistic testing, see
    # https://github.com/sul-dlss/common-accessioning/issues/1364
    # Though then it will be necessary to somehow kill the poller thread, or provide the
    # option to run for only a limited time (via e.g. idle_timeout option to QueuePoller#poll).
    # Perhaps the infra integration test suite will suffice for realistic regression testing.
    allow(poller).to receive(:poll).and_yield(sqs_msg)
  end

  describe '#poll' do
    let(:sqs_watcher_poll) do
      sqs_watcher.poll do |sqs_msg|
        message_handler.process_done_message(sqs_msg)
      end
    end

    describe 'no error is raised by the handler' do
      before { sqs_watcher_poll }

      it 'yields the SQS message received by the poller to the provided block' do
        expect(message_handler).to have_received(:process_done_message).with(sqs_msg)
      end

      it 'does not log an error or notify Honeybadger' do
        expect(Honeybadger).not_to have_received(:notify)
        expect(logger).not_to have_received(:error)
      end
    end

    describe 'an error is raised by the handler' do
      let(:err_msg) { 'uh-oh' }
      let(:handler_error) { StandardError.new(err_msg) }

      before do
        allow(message_handler).to receive(:process_done_message).and_raise(handler_error)
      end

      it 'throws a :skip_delete so that the message stays on the queue, to be picked up again' do
        expect { sqs_watcher_poll }.to throw_symbol(:skip_delete)
      end

      it 'logs an error and notifies Honeybadger' do
        catch :skip_delete do
          sqs_watcher_poll
        end
        context = { sqs_msg:, error: handler_error }
        expect(Honeybadger).to have_received(:notify).with('Error processing SQS message, skipping deletion to allow requeue', context:)
        expect(logger).to have_received(:error).with("Error processing SQS message, skipping deletion to allow requeue. Context: #{context}")
      end
    end
  end
end
