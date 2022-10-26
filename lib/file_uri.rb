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
    File.join(*escaped_parts)
  end

  def path_parts
    File.dirname(@raw).split('/').tap do |parts|
      parts << File.basename(@raw)
    end
  end

  def escaped_parts
    path_parts.map { |part| escape(part) }
  end

  def escape(str)
    CGI.escape(str).gsub(/\+/, '%20')
  end
end
