require 'thread'
require 'concurrent'
require 'securerandom'

require_relative 'utils/ext.rb'
require_relative 'utils/librsync.rb'
require_relative 'utils/turbo_patch.rb'
require_relative 'utils/xxhash.rb'
require_relative 'utils/zip_helper.rb'
require_relative 'utils/file_helper.rb'
require_relative 'utils/thread_pool.rb'
require_relative 'utils/packer.rb'
require_relative 'utils/stopwatch.rb'
require_relative 'utils/delta_file_verifier.rb'
require_relative 'utils/progress_bar.rb'

module PatchKitVersionDiff
  def self.get_diff_summary(content_files:, signature_files:, unchanged_files:, output_file_size:, uncompressed_size:,
                            compression_method:, encryption_method:)

    # skip directories, the server does the same
    content_files = content_files.select { |f| !f.end_with?("/") }
    signature_files = signature_files.select { |f| !f.end_with?("/") }

    removed_files = signature_files - content_files
    added_files = content_files - signature_files
    modified_files = content_files & signature_files

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
  # signatures_dir is a directory with unpacked signatures files.
  # signatures_are_underscored is a boolean flag that indicates if signatures files (not directories) might be saved with '_' postfix at the end of it,
  # this is sometimes done to prevent the operating system from calling file scanning on dll and exe files
  def self.create_diff(files_dir, signatures_dir, temp_dir, output_file,
                       packaging_algorithm: :zip,
                       delta_algorithm: :librsync,
                       pack1_key: nil,
                       previous_files_hashes:, # the format is path => hash string (hex)
                       signatures_are_underscored: false
  )

    if packaging_algorithm == :pack1
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

      # Signatures files might be saved with '_' postfix at the end of it
      signature_files_names = signature_files.map { |f| signatures_are_underscored && !File.directory?(f) ? f.chomp('_') : f }

      progress_bar = ProgressBar.new(content_files.size)

      file_number = 1
      progress_bar.print(file_number, "Preparing file #{file_number} of #{content_files.size}")

      Stopwatch.measure(label: "Preparing") do
        content_files.each do |content_file|
          content_file_abs = File.join(files_dir, content_file)

          # skip all the dirs, this is the default behavior
          next unless File.file? content_file_abs

          if signature_files_names.include? content_file
            # File changed, add delta
            pool.post do
              begin
                signature_file_abs = File.join(signatures_dir, content_file)

                # readd underscore if it was removed
                signature_file_abs += '_' if signatures_are_underscored

                raise "Signature file #{signature_file_abs} does not exist" unless File.exist?(signature_file_abs)

                delta_file_abs = File.join(temp_dir, content_file)
                delta_file_abs_dir = File.dirname(delta_file_abs)

                FileUtils.mkdir_p delta_file_abs_dir unless File.directory?(delta_file_abs_dir)

                build_delta(signature_file: signature_file_abs, content_file: content_file_abs,
                            target_file_path: delta_file_abs, algorithm: delta_algorithm,
                            temp_dir: temp_dir)

                raise "Delta file #{delta_file_abs} does not exist" unless File.exist?(delta_file_abs)

                xxhash_int = ::PatchKitTools::Xxhash.hash(content_file_abs, :xxh32, 42)
                if previous_files_hashes.present? && previous_files_hashes[content_file].to_i(16) == xxhash_int
                  unchanged_files << content_file
                end

                queue << { delta_file_path: delta_file_abs, content_file_name: content_file }
              rescue => e
                puts "Error while processing file #{content_file}: #{e}"
                puts e.backtrace
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

        packer = Packer.open(output_file, algorithm: packaging_algorithm, key: pack1_key) do |packer|
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
      puts

      output_file_size =
        if output_file.is_a?(Array)
          File.size(output_file[0])
        else
          File.size(output_file)
        end

      diff_summary = get_diff_summary(
        content_files: add_slashes_to_empty_dirs(files_dir, content_files),
        signature_files: add_slashes_to_empty_dirs(signatures_dir, signature_files_names),
        unchanged_files: unchanged_files,
        output_file_size: output_file_size,
        uncompressed_size: FileHelper.get_dir_size(files_dir),
        compression_method: packaging_algorithm == :zip ? "zip" : "pack1",
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

  def self.build_delta(signature_file:, content_file:, target_file_path:, algorithm:, temp_dir:)
    temp_signature_path = File.join(temp_dir, "___sig#{SecureRandom.hex(6)}")

    case algorithm&.to_sym
    when :librsync
      Librsync.rs_rdiff_delta(signature_file, content_file, target_file_path)
    when :turbopatch
      # turbopatch requires building a signature file out of target file
      block_size = read_block_len(signature_file)
      Librsync.rs_rdiff_sig(content_file, temp_signature_path, block_size)

      raise "Couldn't create new signature path" unless File.exist?(temp_signature_path)

      ::PatchKitTools::TurboPatch.delta(signature_file, temp_signature_path, content_file, target_file_path,
                                        1024 * 1024 * 128) # the same magic number as on the server
    end
  ensure
    File.unlink(temp_signature_path) if temp_signature_path && File.exist?(temp_signature_path)
  end

  def self.read_block_len(signature_file)
    File.open(signature_file, 'rb') do |file|
      # Skip the magic number (4 bytes)
      file.seek(4, IO::SEEK_SET)

      # Read block_len (4 bytes)
      read_bytes = file.read(4)
      if read_bytes.nil?
        puts "Couldn't read block length from signature file #{signature_file}, will try again in 5 seconds..."
        sleep 5
        read_bytes = file.read(4)

        raise "Couldn't read block length from signature file #{signature_file}" if read_bytes.nil?
      end

      block_len = read_bytes.unpack('L')[0]
      block_len
    end
  end
end
