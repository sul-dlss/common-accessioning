# frozen_string_literal: true

describe Dor::TextExtraction::DorEventLogger do
  subject(:dor_event_logger) { described_class.new(logger:) }

  let(:logger) { instance_double(Logger) }
  let(:type) { 'test-event' }
  let(:data) { { a_result_message: 'for example, or some other helpful context' } }
  let(:druid) { 'bc123df4567' }
  let(:events_client) { instance_double(Dor::Services::Client::Events, create: nil) }
  let(:dor_object_client) { instance_double(Dor::Services::Client::Object, events: events_client) }

  before do
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(dor_object_client)
    allow(Dor::Services::Client).to receive(:configure)
  end

  it 'is configured correctly' do
    dor_event_logger # just create the instance, don't need to do anything with it
    expect(Dor::Services::Client).to have_received(:configure).with(logger:, url: Settings.dor_services.url, token: Settings.dor_services.token)
  end

  it 'creates the event' do
    dor_event_logger.create_event(druid:, type:, data:)
    expect(events_client).to have_received(:create).with(type:, data:)
  end
end
