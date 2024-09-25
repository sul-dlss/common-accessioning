# frozen_string_literal: true

require 'spec_helper'

describe Robots::DorRepo::SpeechToText::SttCreate do
  subject(:perform) { test_perform(robot, druid) }

  let(:druid) { 'druid:bb222cc3333' }
  let(:robot) { described_class.new }
  let(:aws_client) { instance_double(Aws::SQS::Client) }

  before do
    allow(Aws::SQS::Client).to receive(:new).and_return(aws_client)
  end

  context 'when the message is sent successfully' do
    let(:message_body) { { druid:, options: { model: 'large', max_line_count: 80, beam_size: 10 } }.to_json }

    before do
      allow(aws_client).to receive(:send_message).with({ queue_url: Settings.aws.sqs_queue_url, message_body: }).and_return(true)
    end

    it 'sends SQS messages but does not complete the step' do
      expect(perform.status).to eq 'noop'
      expect(aws_client).to have_received(:send_message).with({ queue_url: Settings.aws.sqs_queue_url, message_body: }).once
    end
  end

  context 'when the message is not sent successfully' do
    before do
      allow(aws_client).to receive(:send_message).and_raise(Aws::SQS::Errors::ServiceError.new(nil, 'blam'))
    end

    it 'raises an exception' do
      expect { perform }.to raise_error(RuntimeError, 'Error sending SQS message: blam')
    end
  end
end
