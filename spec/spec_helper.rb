# frozen_string_literal: true

require 'simplecov'

SimpleCov.start do
  track_files 'bin/**/*'
  track_files 'lib/dor/*.rb'
  track_files 'robots/**/*.rb'
  add_filter '/spec/'

  if ENV['CI']
    require 'simplecov_json_formatter'

    formatter SimpleCov::Formatter::JSONFormatter
  end
end

ENV['ROBOT_ENVIRONMENT'] = 'test'
require File.expand_path("#{__dir__}/../config/boot")

require 'debug'
require 'pry'
require 'rspec'
require 'webmock/rspec'
WebMock.disable_net_connect!
require 'equivalent-xml/rspec_matchers'
require 'cocina/rspec'
include LyberCore::Rspec # rubocop:disable Style/MixinUsage

TMP_ROOT_DIR = 'tmp/test_input'

RSpec.configure do |config|
  config.order = :random
  config.default_formatter = 'doc' if config.files_to_run.one?

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'
end

# Require all support files
Dir["#{__dir__}/support/**/*.rb"].each { |f| require f }

# Use rsync to create a copy of the test_input directory that we can modify.
def clone_test_input(destination)
  source = 'spec/test_input'
  system "rsync -rqOlt --delete #{source}/ #{destination}/"
end

# rubocop:disable Metrics/ParameterLists
def build_file(filename, preserve: true, shelve: true, corrected: false, sdr_generated: false, language_tag: nil)
  extension = File.extname(filename)
  mimetype = { '.pdf' => 'application/pdf', '.tif' => 'image/tiff', '.jpg' => 'image/jpeg', '.txt' => 'text/plain',
               '.m4a' => 'audio/mp4', '.mp4' => 'video/mp4', '.vtt' => 'text/vtt', '.xml' => 'application/xml' }
  sdr_value = instance_double(Cocina::Models::FileAdministrative, sdrPreserve: preserve, shelve:)
  instance_double(Cocina::Models::File, administrative: sdr_value, hasMimeType: mimetype[extension], languageTag: language_tag,
                                        filename:, correctedForAccessibility: corrected, sdrGeneratedText: sdr_generated)
end
# rubocop:enable Metrics/ParameterLists
