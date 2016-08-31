#!/usr/bin/env ruby

require_relative 'lib/patchkit_api.rb'
require_relative 'lib/patchkit_tools.rb'
require_relative 'lib/librsync.rb'
require_relative 'lib/zip_helper.rb'


options = PatchKitTools::Options.new("diff-version", "Creates version diff from previous version signatures zip and new version files.",
                                     "-s <signatures> -f <files> -d <diff> -m <diff_summary>")

options.parse(__FILE__ != $0 ? $passed_args : ARGV) do |opts|
  opts.separator "Mandatory"

  opts.on("-s", "--signatures <signatures>",
    "zip with previous version signatures",
    "learn how to get signatures - type 'patchkit-tools download-version-signatures --help'") do |signatures|
    options.signatures = signatures
  end

  opts.on("-f", "--files <files>",
    "directory with new version files") do |files|
    options.files = files
  end

  opts.on("-d", "--diff <diff>",
    "output diff file") do |diff|
    options.diff = diff
  end

  opts.on("-m", "--diffsummary <diff_summary>",
    "output diff summary file") do |diff_summary|
    options.diff_summary = diff_summary
  end
end

options.error_argument_missing("signatures") if options.signatures.nil?
options.error_argument_missing("files") if options.files.nil?
options.error_argument_missing("diff") if options.diff.nil?
options.error_argument_missing("diffsummary") if options.diff_summary.nil?

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
def create_diff(content_dir, signatures_dir, temp_dir, output_file)
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

    puts "Packing diff..."
    # Zip all of the files to output
    ZipHelper.zip(output_file, archive_files)

    # Generate and return diff summary
    return get_diff_summary(content_files, signature_files, File.size(output_file))
  ensure
    # Delete temporary directory
    FileUtils.rm_rf temp_dir
  end
end

temporary_directory = "diff_temporary"
begin
  temporary_signatures_directory = "#{temporary_directory}/signatures"
  temporary_diff_directory = "#{temporary_directory}/diff"

  puts "Unpacking signatures..."
  # Unzip signatures
  ZipHelper.unzip(options.signatures, temporary_signatures_directory)

  puts "Creating diff..."
  # Create diff
  diff_summary = create_diff(options.files, temporary_signatures_directory, temporary_diff_directory, options.diff)

  puts "Saving diff summary..."
  # Write diff summary
  diff_summary_file = File.open(options.diff_summary, 'wb')
  begin
    diff_summary_file.write diff_summary
  ensure
    diff_summary_file.close
  end

  puts "Done!"
ensure
  # Delete temporary directory
  FileUtils.rm_rf temporary_directory
end
