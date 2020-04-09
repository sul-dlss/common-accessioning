# frozen_string_literal: true

# Produces properly URI escaped files
class FileUri
  # @param [String] pathname an unescaped path to a file.
  def initialize(pathname)
    @raw = pathname
  end

  def uri
    URI::File.build(path: escaped_path)
  end

  delegate :to_s, to: :uri

  private

  def escaped_path
    File.join(File.dirname(@raw), escaped_filename)
  end

  def escaped_filename
    CGI.escape(File.basename(@raw)).gsub(/\+/, '%20')
  end
end
