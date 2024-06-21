# frozen_string_literal: true

# Shared context for setting up and tearing down ABBYY directory
shared_context 'with abbyy dir' do
  around do |example|
    Dir.mktmpdir('abbyy-') do |dir|
      # Set up ABBYY directories for results and exceptions
      result_xml_path = File.join(dir, 'RESULTXML')
      exceptions_path = File.join(dir, 'EXCEPTIONS')
      xml_ticket_path = File.join(dir, 'INPUT')
      abbyy_output_path = File.join(dir, 'OUTPUT')
      Dir.mkdir(result_xml_path)
      Dir.mkdir(exceptions_path)
      Dir.mkdir(xml_ticket_path)
      Dir.mkdir(abbyy_output_path)

      # Make the directories available to the test
      @abbyy_root_path = dir
      @abbyy_result_xml_path = result_xml_path
      @abbyy_exceptions_path = exceptions_path
      @abbyy_xml_ticket_path = xml_ticket_path
      @abbyy_output_path = abbyy_output_path
      example.run
    end
  end

  attr_reader :abbyy_root_path, :abbyy_result_xml_path, :abbyy_exceptions_path, :abbyy_xml_ticket_path, :abbyy_output_path
end

# Create a stub ABBYY result file with optional error status, contents, etc.
def create_abbyy_result(base_path, druid:, run_index: 0, success: true, contents: '')
  index_tag = run_index.positive? ? '.%04d'.format(run_index) : ''
  filename = File.join(base_path, "#{druid}#{index_tag}.xml.result.xml")
  change_fs(:added, filename, "<XmlResult IsFailed=\"#{!success}\">#{contents}</XmlResult>")
end

def copy_abbyy_alto(output_path:, contents:, druid:)
  Dir.mkdir(output_path)
  filename = File.join(output_path, "#{druid}.xml")
  change_fs(:added, filename, contents)
end

### Below are adapted from Listen's spec/support/acceptance_helpers.rb ###

# rubocop:disable Metrics/MethodLength, Metrics/AbcSize
def change_fs(type, path, contents)
  case type
  when :modified
    File.exist?(path) or raise "Bad test: cannot modify #{path.inspect} (it doesn't exist)"

    # wait until full second, because this might be followed by a modification
    # event (which otherwise may not be detected every time)
    _sleep_until_next_second(Pathname.pwd)

    File.open(path, 'a') { |f| f.write(contents) }

    # separate it from upcoming modifications"
    _sleep_to_separate_events
  when :added
    File.exist?(path) and raise "Bad test: cannot add #{path.inspect} (it already exists)"

    # wait until full second, because this might be followed by a modification
    # event (which otherwise may not be detected every time)
    _sleep_until_next_second(Pathname.pwd)

    File.write(path, contents)

    # separate it from upcoming modifications"
    _sleep_to_separate_events
  when :removed
    File.exist?(path) or raise "Bad test: cannot remove #{path.inspect} (it doesn't exist)"
    File.unlink(path)
  else
    raise "bad test: unknown type: #{type.inspect}"
  end
end
# rubocop:enable Metrics/MethodLength, Metrics/AbcSize

# Used by change_fs() above so that the FS change (e.g. file created) happens
# as close to the start of a new second (time) as possible.
#
# E.g. if file is created at 1234567.999 (unix time), it's mtime on some
# filesystems is rounded, so it becomes 1234567.0, but if the change
# notification happens a little while later, e.g. at 1234568.111, now the file
# mtime and the current time in seconds are different (1234567 vs 1234568), and
# so the MD5 test won't kick in (see file.rb) - the file will not be considered
# for content checking (sha), so File.change will consider the file unmodified.
#
# This means, that if a file is added at 1234567.888 (and updated in Record),
# and then its content is modified at 1234567.999, and checking for changes
# happens at 1234568.111, the modification won't be detected.
# (because Record mtime is 1234567.0, current FS mtime from stat() is the
# same, and the checking happens in another second - 1234568).
#
# So basically, adding a file and detecting its later modification should all
# happen within 1 second (which makes testing and debugging difficult).
#
def _sleep_until_next_second(path)
  Listen::File.inaccurate_mac_time?(path)

  t = Time.now.utc
  diff = t.to_f - t.to_i

  sleep(1.05 - diff)
end

def _sleep_to_separate_events
  # separate the events or Darwin and Polling
  # will detect only the :added event
  #
  # (This is because both use directory scanning which may not kick in time
  # before the next filesystem change)
  #
  # The minimum for this is the time it takes between a syscall
  # changing the filesystem ... and ... an async
  # Listen::File.scan to finish comparing the file with the
  # Record
  #
  # This necessary for:
  # - Darwin Adapter
  # - Polling Adapter
  # - Linux Adapter in FSEvent emulation mode
  # - maybe Windows adapter (probably not)
  sleep(0.4)
end
