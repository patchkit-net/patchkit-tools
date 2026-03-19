require 'rubygems'
require 'bundler/setup'
require 'zip'

require_relative 'windows_long_path'

Zip.write_zip64_support = true

module ZipHelper
  def self.unzip(zip_file, destination_path, add_underscores_to_files: false)
    FileUtils.mkdir_p(WindowsLongPath.fix(destination_path)) unless File.directory?(WindowsLongPath.fix(destination_path))

    Zip::File.foreach(zip_file) do |zip_entry|
      extract_file_path = "#{destination_path}/#{zip_entry.name}"
      extract_file_path += '_' if add_underscores_to_files && !zip_entry.directory?
      extract_dir_path = File.dirname(extract_file_path)

      FileUtils.mkdir_p(WindowsLongPath.fix(extract_dir_path)) unless File.directory?(WindowsLongPath.fix(extract_dir_path))
      file = open(WindowsLongPath.fix(extract_file_path), 'wb')
      begin
        IO.copy_stream(zip_entry.get_input_stream, file)
      ensure
        file.close
      end
    end
  end

  def self.zip(zip_file, file_hash)
    WindowsLongPath.safe_rm_rf(zip_file) if File.exist?(zip_file)
    Zip.default_compression = 2
    Zip::File.open(zip_file, Zip::File::CREATE) do |zip|
      file_hash.each do |source, destination|
        zip.add(destination, WindowsLongPath.fix(source))
      end
    end
  end
end
