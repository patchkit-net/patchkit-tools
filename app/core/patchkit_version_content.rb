require_relative 'utils/zip_helper.rb'
require_relative 'utils/file_helper.rb'

module PatchKitVersionContent
  def self.create_content(files_dir, output_file)
    archive_files = {}

    FileHelper::list_relative(files_dir).each do |file|
      archive_files[File.join(files_dir, file)] = file
    end

    ZipHelper::zip(output_file, archive_files)
  end
end
