# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Accession::StartAccession do
  subject(:robot) { described_class.new }

  let(:druid) { 'druid:zz000zz0001' }
  let(:object_client) { instance_double(Dor::Services::Client::Object, version: version_client) }
  let(:version_client) do
    instance_double(Dor::Services::Client::ObjectVersion,
                    status: instance_double(Dor::Services::Client::ObjectVersion::VersionStatus, open?: version_open))
  end
  let(:version_open) { false }

  before do
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
  end

  describe '#perform' do
    subject(:perform) { test_perform(robot, druid) }

    before { allow(Honeybadger).to receive(:notify) }

    it 'does not notify Honeybadger' do
      perform
      expect(Honeybadger).not_to have_received(:notify)
    end

    context 'when object is still open' do
      let(:version_open) { true }

      it 'notifies Honeybadger' do
        perform
        expect(Honeybadger).to have_received(:notify).once.with('[WARNING] Accessioning has been started with an object that is still open')
      end
    end
  end
end
