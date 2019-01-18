#!/usr/bin/env ruby
# frozen_string_literal: true

abort "Usage: #{$PROGRAM_NAME} COLOR..." if ARGV.empty?

ARGV.each do |color|
  cmd = "convert -size 100x100 xc:#{color} -profile sRGBIEC6196621.icc #{color}.tif"
  system cmd
end
