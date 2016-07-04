#!/usr/bin/env ruby

require_relative 'lib/librsync.rb'
require_relative 'lib/patchkit_api.rb'
require_relative 'lib/patchkit_tools.rb'
require_relative 'lib/zip_helper.rb'


options = PatchKitTools::Options.new

options.parse("app-versions-diff", __FILE__ != $0 ? $passed_args : ARGV) do |opts|
  opts.on("-s", "--signature SIGNATURE_FILE",
    "file with previous version signatures",
    "read more - type 'patchkit-tools app-versions-signature --help'") do |signature|
    options.signature = signature
  end

  opts.on("-f", "--files FILES_DIRECTORY",
    "directory with the newest version files") do |files|
    options.files = files
  end

  opts.on("-d", "--diff DIFF_FILE",
    "output diff file") do |diff|
    options.diff = diff
  end

  opts.on("-u", "--summary SUMMARY_FILE",
    "output summary file") do |summary|
    options.summary = summary
  end
end

options.error_argument_missing("signature") if options.signature.nil?
options.error_argument_missing("files") if options.files.nil?
options.error_argument_missing("diff") if options.diff.nil?
options.error_argument_missing("summary") if options.summary.nil?

def list_relative(dir, pattern="**/*")
  dir = dir.gsub('\\','/')
  dir_path = Pathname.new(dir)
  Dir.glob("#{dir}/#{pattern}").map do |e|
    Pathname.new(e).relative_path_from(dir_path).to_s
  end
end

def create_diff(content_dir, signatures_dir, temp_dir, output_file)
  begin
    FileUtils.mkdir_p temp_dir unless File.directory?(temp_dir)

    content_files = list_relative(content_dir)
    signature_files = list_relative(signatures_dir)
    archive_files = {}

    content_files.each do |content_file|
      content_file_abs = File.join(content_dir, content_file)
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
        # File added
        archive_files[content_file_abs] = content_file
      end
    end

    zip(output_file, archive_files)

    removed_files = signature_files - content_files
    added_files = content_files - signature_files
    modified_files = content_files - added_files

    diff_summary = Hash.new
    diff_summary["size"] = File.size(output_file)
    diff_summary["compression_method"] = "zip"
    diff_summary["encryption_method"] = "none"
    diff_summary["added_files"] = []
    diff_summary["modified_files"] = []
    diff_summary["removed_files"] = []

    added_files.each { |f| diff_summary["added_files"] << f }
    modified_files.each { |f| diff_summary["modified_files"] << f }
    removed_files.each { |f| diff_summary["removed_files"] << f }

    JSON.generate(diff_summary)
  ensure
    FileUtils.rm_rf temp_dir
  end
end

begin
  FileUtils.mkdir_p "diff_temporary" unless File.directory?("diff_temp")
  unzip(options.signature, "diff_temporary/signatures")
  file = File.open(options.summary, 'w')
  begin
    file.write create_diff(options.files, "diff_temporary/signatures", "diff_temporary/temp", options.diff)
  ensure
    file.close
  end
ensure
  FileUtils.rm_rf "diff_temporary"
end
