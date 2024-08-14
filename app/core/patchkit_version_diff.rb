require 'thread'
require 'concurrent'

require_relative 'utils/librsync.rb'
require_relative 'utils/zip_helper.rb'
require_relative 'utils/file_helper.rb'
require_relative 'utils/thread_pool.rb'
require_relative 'utils/packer.rb'
require_relative 'utils/stopwatch.rb'
require_relative 'utils/delta_file_verifier.rb'

module PatchKitVersionDiff
  def self.get_diff_summary(content_files:, signature_files:, unchanged_files:, output_file_size:, uncompressed_size:,
                            compression_method:, encryption_method:)

    # skip directories, TODO: Verify if server does the same
    content_files = content_files.select { |f| !f.end_with?("/") }

    removed_files = signature_files - content_files
    added_files = content_files - signature_files
    modified_files = content_files - added_files

    diff_summary = Hash.new
    diff_summary["size"] = output_file_size
    diff_summary["uncompressed_size"] = uncompressed_size
    diff_summary["compression_method"] = compression_method
    diff_summary["encryption_method"] = encryption_method
    diff_summary["unchanged_files"] = unchanged_files
    diff_summary["added_files"] = []
    diff_summary["modified_files"] = []
    diff_summary["removed_files"] = []

    added_files.each { |f| diff_summary["added_files"] << f }
    modified_files.each { |f| diff_summary["modified_files"] << f }
    removed_files.each { |f| diff_summary["removed_files"] << f }

    JSON.generate(diff_summary)
  end

  # Creates diff and returns diff summary
  def self.create_diff(files_dir, signatures_dir, temp_dir, output_file, algorithm: :zip, pack1_key: nil)
    if algorithm == :pack1
      raise "Pack1 key must be set for pack1 algorithm" if pack1_key.nil?
    end

    begin
      queue = Queue.new
      pool = Concurrent::FixedThreadPool.new(PatchKitConfig.rdiff_thread_count)
      sha1 = nil

      FileUtils.mkdir_p temp_dir unless File.directory?(temp_dir)

      content_files = FileHelper.list_relative(files_dir)
      unchanged_files = []
      signature_files = FileHelper.list_relative(signatures_dir)
      progress_bar = ProgressBar.new(content_files.size)

      file_number = 1
      progress_bar.print(file_number, "Preparing file #{file_number} of #{content_files.size}")

      Stopwatch.measure(label: "Preparing") do
        content_files.each do |content_file|
          content_file_abs = File.join(files_dir, content_file)

          next unless File.file? content_file_abs

          if signature_files.include? content_file
            # File changed, add delta
            pool.post do
              begin
                signature_file_abs = File.join(signatures_dir, content_file)

                delta_file_abs = File.join(temp_dir, content_file)
                delta_file_abs_dir = File.dirname(delta_file_abs)

                FileUtils.mkdir_p delta_file_abs_dir unless File.directory?(delta_file_abs_dir)

                Librsync.rs_rdiff_delta(signature_file_abs, content_file_abs, delta_file_abs)
                unchanged_files << content_file if DeltaFileVerifier.verify(delta_file_abs)

                queue << { delta_file_path: delta_file_abs, content_file_name: content_file}
              rescue => e
                puts "Error while processing file #{content_file}: #{e}"
                puts
              end
            end
          else
            # New file added, add content path instead of diff
            queue << { delta_file_path: content_file_abs, content_file_name: content_file}
          end
        end

        pool.shutdown # start the shutdown procedure

        if output_file.is_a?(Array)
          output_file.each do |f|
            FileUtils.rm_rf f if File.exist? f
          end
        else
          FileUtils.rm_rf output_file if File.exist? output_file
        end

        packer = Packer.open(output_file, algorithm: algorithm, key: pack1_key) do |packer|
          loop do
            break if queue.empty? && pool.shutdown?

            file_info = queue.pop

            if file_info.nil?
              sleep 0.1
              next
            end

            packer.add(entry_name: file_info[:content_file_name], source_file_path: file_info[:delta_file_path])

            file_number += 1
            # puts "Adding #{file_info[:content_file_name]} to diff"

            progress_bar.print(file_number, "Processing file #{file_number} of #{content_files.size}")
          end
        end
        sha1 = packer.sha1

        puts
      end

      progress_bar.print(content_files.size, "All files processed!", force: true)

      output_file_size =
        if output_file.is_a?(Array)
          File.size(output_file[0])
        else
          File.size(output_file)
        end

      diff_summary = get_diff_summary(
        content_files: add_slashes_to_empty_dirs(files_dir, content_files),
        signature_files: add_slashes_to_empty_dirs(signatures_dir, signature_files),
        unchanged_files: unchanged_files,
        output_file_size: output_file_size,
        uncompressed_size: FileHelper.get_dir_size(files_dir),
        compression_method: algorithm == :zip ? "zip" : "pack1",
        encryption_method: "none"
      )

      OpenStruct.new(sha1: sha1, diff_summary: diff_summary)

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
