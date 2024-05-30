# frozen_string_literal: true

# Handle setup/teardown of a DOR workspace directory
shared_context 'with workspace dir' do
  around do |example|
    Dir.mktmpdir('workspace-') do |dir|
      @workspace_dir = dir
      example.run
    end
  end

  attr_reader :workspace_dir
end
