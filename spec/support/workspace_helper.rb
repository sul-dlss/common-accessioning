# frozen_string_literal: true

# Handle setup/teardown of a DOR workspace directory
shared_context 'with workspace dir' do
  around do |example|
    Dir.mktmpdir('workspace-') do |dir|
      workspace_dir = dir

      workspace_content_dir = File.join(workspace_dir, 'content')
      FileUtils.mkdir(workspace_content_dir)

      workspace_metadata_dir = File.join(workspace_dir, 'metadata')
      FileUtils.mkdir(workspace_metadata_dir)

      @workspace_dir = workspace_dir
      @workspace_content_dir = workspace_content_dir
      @workspace_metadata_dir = workspace_metadata_dir

      example.run
    end
  end

  attr_reader :workspace_dir, :workspace_content_dir, :workspace_metadata_dir
end

def create_ocr_file(filename)
  fixture_file = "001#{File.extname(filename)}"
  FileUtils.copy(Pathname('spec') / 'fixtures' / 'ocr' / fixture_file, Pathname(workspace_content_dir) / filename)
end

def create_speech_to_text_file(filename)
  fixture_file = "file1#{File.extname(filename)}"
  FileUtils.copy(Pathname('spec') / 'fixtures' / 'speech_to_text' / fixture_file, Pathname(workspace_content_dir) / filename)
end
