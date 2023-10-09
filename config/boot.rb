# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'
require 'active_support' # Required as of Rails 7.1
Bundler.require(:default)

loader = Zeitwerk::Loader.new
loader.push_dir(File.absolute_path("#{__FILE__}/../../lib"))
loader.setup

LyberCore::Boot.up(__dir__)
