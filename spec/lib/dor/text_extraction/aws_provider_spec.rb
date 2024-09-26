# frozen_string_literal: true

describe Dor::TextExtraction::AwsProvider do
  let(:provider) { described_class.new(region:, access_key_id:, secret_access_key:) }
  let(:region) { 'us-west-2' }
  let(:access_key_id) { 'some_key' }
  let(:secret_access_key) { 'secret' }
  let(:bucket_name) { Settings.aws.base_s3_bucket }

  describe '.bucket_name' do
    it 'returns value from Settings' do
      expect(provider.bucket_name).to eq bucket_name
    end
  end

  describe '.configure' do
    let(:config) { provider.client.config }

    it 'injects client configuration' do
      expect(config.region).to eq region
      expect(config.credentials).to be_an(Aws::Credentials)
      expect(config.credentials).to be_set
      expect(config.credentials.access_key_id).to eq access_key_id
      expect(config.credentials.secret_access_key).to eq secret_access_key
    end
  end
end
