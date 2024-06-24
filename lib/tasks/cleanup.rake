# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
namespace :abbyy do
  # ROBOT_ENVIRONMENT=production bundle exec rake abbyy:cleanup
  desc 'Cleanup empty ABBYY input and output directories and older ABBYY tickets'
  task cleanup: :environment do |_task, _args|
    # Delete XML Result files older than 1 week
    result_files = Dir.glob("#{Settings.sdr.abbyy.local_result_path}/*.xml")
    puts "Checking ABBYY result files #{Settings.sdr.abbyy.local_result_path} for deletion: #{result_files.size} files found."
    num_deleted = 0
    result_files.each do |file|
      next unless File.mtime(file) < Time.now - 1.week

      num_deleted += 1
      puts "Deleting ABBYY result file #{file}"
      FileUtils.rm(file)
    end
    puts "Deleted #{num_deleted} ABBYY result files older than 1 week."
    puts

    # Delete ABBYY input directories that are empty and ticket files older than 1 week
    input_entries = Dir.glob("#{Settings.sdr.abbyy.local_ticket_path}/*")
    puts "Checking ABBYY input folders/files #{Settings.sdr.abbyy.local_ticket_path} for deletion: #{input_entries.size} folders found."
    num_deleted = 0
    input_entries.each do |entry|
      if File.directory?(entry) && Dir.empty?(entry)
        num_deleted += 1
        puts "Deleting empty ABBYY input directory #{entry}"
        FileUtils.rm_rf(entry)
      elsif File.file?(entry) && File.mtime(entry) < Time.now - 1.week
        num_deleted += 1
        puts "Deleting ABBYY ticket file #{entry}"
        FileUtils.rm_f(entry)
      end
    end
    puts "Deleted #{num_deleted} empty input folders or XML files older than 1 week."
    puts

    # Delete ABBYY output directories that are empty
    output_dirs = Dir.glob("#{Settings.sdr.abbyy.local_output_path}/*")
    puts "Checking ABBYY output folders #{Settings.sdr.abbyy.local_output_path} for deletion: #{output_dirs.size} folders found."
    num_deleted = 0
    output_dirs.each do |dir|
      next unless File.directory?(dir) && Dir.empty?(dir)

      num_deleted += 1
      puts "Deleting empty ABBYY output directory #{dir}"
      FileUtils.rm_rf(dir)
    end
    puts "Deleted #{num_deleted} empty output folders."
    puts

    # Delete exception files older than 1 month
    exception_files = Dir.glob("#{Settings.sdr.abbyy.local_exception_path}/*.*")
    puts "Checking ABBYY exception files #{Settings.sdr.abbyy.local_exception_path} for deletion: #{exception_files.size} files found."
    num_deleted = 0
    exception_files.each do |file|
      next unless File.mtime(file) < Time.now - 1.month

      num_deleted += 1
      puts "Deleting exception file #{file}"
      FileUtils.rm_f(file)
    end
    puts "Deleted #{num_deleted} exception files older than 1 month."
  end
end
# rubocop:enable Metrics/BlockLength
