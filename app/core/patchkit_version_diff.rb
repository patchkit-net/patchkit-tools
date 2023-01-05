require 'thread'

require_relative 'utils/librsync.rb'
require_relative 'utils/zip_helper.rb'
require_relative 'utils/file_helper.rb'
require_relative 'utils/thread_pool.rb'

module PatchKitVersionDiff
  def self.get_diff_summary(content_files, signature_files, output_file_size)
    removed_files = signature_files - content_files
    added_files = content_files - signature_files
    modified_files = content_files - added_files

    diff_summary = Hash.new
    diff_summary["size"] = output_file_size
    diff_summary["compression_method"] = "zip"
    diff_summary["encryption_method"] = "none"
    diff_summary["added_files"] = []
    diff_summary["modified_files"] = []
    diff_summary["removed_files"] = []

    added_files.each { |f| diff_summary["added_files"] << f }
    modified_files.each { |f| diff_summary["modified_files"] << f }
    removed_files.each { |f| diff_summary["removed_files"] << f }

    JSON.generate(diff_summary)
  end

  # Creates diff and returns diff summary
  def self.create_diff(files_dir, signatures_dir, temp_dir, output_file)
    begin
      FileUtils.mkdir_p temp_dir unless File.directory?(temp_dir)

      content_files = FileHelper.list_relative(files_dir)
      signature_files = FileHelper.list_relative(signatures_dir)
      archive_files = {}

      progress_bar = ProgressBar.new(content_files.size)

      file_number = 0

      pool = ThreadPool.new(size: PatchKitConfig.rdiff_thread_count)
      semaphore = Mutex.new

      Stopwatch.measure(label: "Preparing") do
        content_files.each do |content_file|
          content_file_abs = File.join(files_dir, content_file)

          next unless File.file? content_file_abs

          if signature_files.include? content_file
            # File changed, add delta
            pool.enqueue do
              semaphore.synchronize do
                file_number += 1
                progress_bar.print(file_number, "Preparing file #{file_number} of #{content_files.size}")
              end

              signature_file_abs = File.join(signatures_dir, content_file)

              delta_file_abs = File.join(temp_dir, content_file)
              delta_file_abs_dir = File.dirname(delta_file_abs)

              FileUtils.mkdir_p delta_file_abs_dir unless File.directory?(delta_file_abs_dir)

              Librsync.rs_rdiff_delta(signature_file_abs, content_file_abs, delta_file_abs)

              semaphore.synchronize do
                archive_files[delta_file_abs] = content_file
              end
            end
          else
            semaphore.synchronize do
              file_number += 1
              progress_bar.print(file_number, "Preparing file #{file_number} of #{content_files.size}")
            end

            # File added, add content
            archive_files[content_file_abs] = content_file
          end
        end

        pool.execute

        progress_bar.print(content_files.size, "All files processed!", force: true)
      end

      puts "Zipping diff file..."

      Stopwatch.measure(label: "Zipping") do
        ZipHelper.zip(output_file, archive_files)
      end

      return get_diff_summary(
        add_slashes_to_empty_dirs(files_dir, content_files),
        add_slashes_to_empty_dirs(signatures_dir, signature_files),
        File.size(output_file)
      )
    ensure
      FileUtils.rm_rf temp_dir
    end
  end

  def self.add_slashes_to_empty_dirs(base_dir, files)
    files.map do |f|
      path = File.join(base_dir, f)
      File.directory?(path) ? "#{f}/" : f
    end
  end
end
