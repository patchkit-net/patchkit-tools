require_relative 'utils/zip_helper'
require_relative 'utils/file_helper'
require_relative 'utils/stopwatch'

module PatchKitVersionContent
  def self.create_content(files_dir, output_file)
    archive_files = {}

    FileHelper.list_relative(files_dir).each do |file|
      begin
        unless file.tr("\u2018", "'").tr("\u2019", "'").ascii_only?
          puts
          puts "Warning: Skipping file with non-ASCII characters: #{file}"
          next
        end
      rescue Encoding::CompatibilityError => e
        puts
        puts "Warning: Encoding error: Skipping file with non-ASCII characters: #{file}"
        puts e.message
        next
      end

      archive_files[File.join(files_dir, file)] = file
    end

    Stopwatch.measure(label: 'Zipping') do
      ZipHelper.zip(output_file, archive_files)
    end
  end
end
