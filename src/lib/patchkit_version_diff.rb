require_relative 'librsync.rb'
require_relative 'zip_helper.rb'
require_relative 'file_helper.rb'

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

      content_files = FileHelper::list_relative(files_dir)
      signature_files = FileHelper::list_relative(signatures_dir)
      archive_files = {}

      content_files.each do |content_file|
        content_file_abs = File.join(files_dir, content_file)

        next unless File.file? content_file_abs

        if signature_files.include? content_file
          # File changed, add delta
          signature_file_abs = File.join(signatures_dir, content_file)

          delta_file_abs = File.join(temp_dir, content_file)
          delta_file_abs_dir = File.dirname(delta_file_abs)

          FileUtils.mkdir_p delta_file_abs_dir unless File.directory?(delta_file_abs_dir)

          Librsync.rs_rdiff_delta(signature_file_abs, content_file_abs, delta_file_abs)

          archive_files[delta_file_abs] = content_file
        else
          # File added, add content
          archive_files[content_file_abs] = content_file
        end
      end

      ZipHelper.zip(output_file, archive_files)

      return get_diff_summary(content_files, signature_files, File.size(output_file))
    ensure
      FileUtils.rm_rf temp_dir
    end
  end
end
