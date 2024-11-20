# frozen_string_literal: true

describe Dor::TextExtraction::SqsWatcher do
  subject(:sqs_watcher) { described_class.new(queue_url:, role_arn:, logger:, visibility_timeout:) }

  let(:queue_url) { Settings.aws.speech_to_text.sqs_done_queue_url }
  let(:region) { Settings.aws.region }
  let(:access_key_id) { Settings.aws.access_key_id }
  let(:secret_access_key) { Settings.aws.secret_access_key }
  let(:role_arn) { Settings.aws.speech_to_text.role_arn }
  let(:logger) { instance_double(Logger, info: nil, error: nil, warn: nil) }
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
    # executes the block once.  Another deviation from the real Aws::SQS::QueuePoller is that our
    # mocked #poll won't catch a thrown :skip_delete.  Instead of a complex high-fidelity mock,
    # we go for something simple to make the test obvious, let such throw calls bubble up,
    # and check for the throw on invocation of #poll.  Basically, trying to avoid subtle bugs in
    # the test code, to make it more obvious that the test is exercising handler invocation, logging,
    # and retry behavior in a way that doesn't hide bugs.
    # TODO: there is a ticket for investigating localstack for more realistic testing, see
    # https://github.com/sul-dlss/common-accessioning/issues/1364
    # Though then it will be necessary to somehow kill the poller thread, or provide the
    # option to run for only a limited time (via e.g. idle_timeout option to QueuePoller#poll).
    # Perhaps the infra integration test suite will suffice for realistic regression testing.
    allow(poller).to receive(:poll).and_yield(sqs_msg)
    allow(sqs_msg).to receive(:[]).with(:attributes).and_return({ 'ApproximateReceiveCount' => '1' })
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
        expect(logger).to have_received(:warn).with("Error processing SQS message, skipping deletion to allow requeue. Context: #{context}")
      end

      describe 'retry' do
        context 'when the operation succeeds before the max number of attempts is exceeded' do
          before do
            allow(message_handler).to receive(:process_done_message) do |msg|
              approx_receive_count = msg[:attributes]['ApproximateReceiveCount'].to_i
              msg[:attributes]['ApproximateReceiveCount'] = (approx_receive_count + 1).to_s
              raise handler_error unless approx_receive_count > 2
            end
          end

          it 'throws :skip_delete for the attempts that happen before the max number of attempts is reached, and notifies/warns accordingly' do
            expect { sqs_watcher_poll }.to throw_symbol(:skip_delete)
            expect { sqs_watcher_poll }.to throw_symbol(:skip_delete)
            expect { sqs_watcher_poll }.not_to throw_symbol(:skip_delete)
            context = { sqs_msg:, error: handler_error }
            expect(logger).to have_received(:warn).with("Error processing SQS message, skipping deletion to allow requeue. Context: #{context}").twice
            expect(Honeybadger).to have_received(:notify).with('Error processing SQS message, skipping deletion to allow requeue', context:).twice
            expect(logger).not_to have_received(:error)
            expect(Honeybadger).not_to have_received(:notify).with(/retries exceeded for message/, context: anything)
          end
        end

        context 'when the operation does not succeed before the max number of attempts is exceeded' do
          before do
            allow(message_handler).to receive(:process_done_message) do |msg|
              approx_receive_count = msg[:attributes]['ApproximateReceiveCount'].to_i
              msg[:attributes]['ApproximateReceiveCount'] = (approx_receive_count + 1).to_s
              raise handler_error
            end
          end

          it 'does not throw :skip_delete on the final attempt, and sends a Honeybadger alert' do
            # as described above in a comment on Aws::SQS::QueuePoller mocking, we trade
            # a mock of Aws::SQS::QueuePoller#poll that behaves exactly like the real thing,
            # for a less complex and more readable test, that hopefully makes it more obvious
            # that the right throws are happening, and that the right number of attempts to process
            # an SQS message is made.  the real poller wouldn't have to be invoked multiple times,
            # because it'd just poll indefinitely for new messages (it'd also catch :skip_delete internally).
            expect { sqs_watcher_poll }.to throw_symbol(:skip_delete)
            expect { sqs_watcher_poll }.to throw_symbol(:skip_delete)
            expect { sqs_watcher_poll }.not_to throw_symbol(:skip_delete)
            context = { sqs_msg:, error: handler_error }
            expect(logger).to have_received(:warn).with("Error processing SQS message, skipping deletion to allow requeue. Context: #{context}").twice
            expect(Honeybadger).to have_received(:notify).with('Error processing SQS message, skipping deletion to allow requeue', context:).twice
            expect(logger).to have_received(:error).with("Max retries exceeded for message, message will be deleted from queue! Context: #{context}")
            expect(Honeybadger).to have_received(:notify).with('Max retries exceeded for message, message will be deleted from queue!', context:)
          end
        end
      end
    end
  end
end
