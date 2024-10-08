# frozen_string_literal: true

describe Dor::TextExtraction::AwsProvider do
  let(:provider) { described_class.new(region:, access_key_id:, secret_access_key:) }
  let(:region) { 'us-west-2' }
  let(:access_key_id) { 'some_key' }
  let(:secret_access_key) { 'secret' }
  let(:bucket_name) { Settings.aws.speech_to_text.base_s3_bucket }
  let(:sqs_todo_queue_url) { Settings.aws.speech_to_text.sqs_todo_queue_url }
  let(:sqs_done_queue_url) { Settings.aws.speech_to_text.sqs_done_queue_url }

  describe '.bucket_name' do
    it 'returns value from Settings' do
      expect(provider.bucket_name).to eq bucket_name
    end
  end

  describe '.sqs_todo_queue_url' do
    it 'returns value from Settings' do
      expect(provider.sqs_todo_queue_url).to eq sqs_todo_queue_url
    end
  end

  describe '.sqs_done_queue_url' do
    it 'returns value from Settings' do
      expect(provider.sqs_done_queue_url).to eq sqs_done_queue_url
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

  context 'when role_arn is provided' do
    let(:role_arn) { Settings.aws.speech_to_text.role_arn }
    let(:provider) { described_class.new(region:, access_key_id:, secret_access_key:, role_arn:) }
    let(:assume_role_credentials) { instance_double(Aws::AssumeRoleCredentials) }

    before do
      allow(Aws::AssumeRoleCredentials).to receive(:new).with(client: an_instance_of(Aws::STS::Client), role_arn:, role_session_name: an_instance_of(String)).and_return(assume_role_credentials)
    end

    it 'configures the credentials with a role_arn value' do
      expect(provider.sqs.config.credentials).to eq assume_role_credentials
      expect(Aws::AssumeRoleCredentials).to have_received(:new).once
    end
  end
end
