require_relative 'librsync.rb'
require_relative 'zip_helper.rb'

module DiffHelper
  # Lists all files in directory
  def list_relative(dir)
    dir = dir.gsub('\\','/')
    dir_path = Pathname.new(dir)
    Dir.glob("#{dir}/**/*").map do |e|
      Pathname.new(e).relative_path_from(dir_path).to_s
    end
  end

  def get_diff_summary(content_files, signature_files, output_file_size)
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
  def self.create_diff(content_dir, signatures_dir, temp_dir, output_file)
    begin
      # Create temporary directory
      FileUtils.mkdir_p temp_dir unless File.directory?(temp_dir)

      # List content files
      content_files = list_relative(content_dir)

      # List signature files
      signature_files = list_relative(signatures_dir)

      archive_files = {}

      # Create diffs for each content file
      content_files.each do |content_file|
        # Get absolute path of content file
        content_file_abs = File.join(content_dir, content_file)

        # Skip if file is actually directory
        next unless File.file? content_file_abs

        # Check if signature exists
        if signature_files.include? content_file
          # File changed, add delta

          # Get signature file absolute path
          signature_file_abs = File.join(signatures_dir, content_file)

          # Get absolute path of delta file
          delta_file_abs = File.join(temp_dir, content_file)
          delta_file_abs_dir = File.dirname(delta_file_abs)

          # Create temporary directory where delta file will be placed
          FileUtils.mkdir_p delta_file_abs_dir unless File.directory?(delta_file_abs_dir)

          # Create delta file
          Librsync.rs_rdiff_delta(signature_file_abs, content_file_abs, delta_file_abs)

          # Register delta file in archive files
          archive_files[delta_file_abs] = content_file
        else
          # File added, add content

          # Register content file in archive files
          archive_files[content_file_abs] = content_file
        end
      end

      # Zip all of the files to output
      ZipHelper.zip(output_file, archive_files)

      # Generate and return diff summary
      return get_diff_summary(content_files, signature_files, File.size(output_file))
    ensure
      # Delete temporary directory
      FileUtils.rm_rf temp_dir
    end
  end
end
