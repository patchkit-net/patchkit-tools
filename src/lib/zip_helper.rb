require 'rubygems'
require 'bundler/setup'
require 'zip'

Zip.write_zip64_support = true

module ZipHelper
  def self.unzip(zip_file, destination_path)
    FileUtils.mkdir_p destination_path unless File.directory?(destination_path)

    Zip::File.foreach(zip_file) do |zip_entry|
      extract_file_path = "#{destination_path}/#{zip_entry.name}"
      extract_dir_path = File.dirname(extract_file_path)

      FileUtils.mkdir_p(extract_dir_path) unless File.directory?(extract_dir_path)

      file = open(extract_file_path, 'wb')
      begin
        IO.copy_stream(zip_entry.get_input_stream, file)
      ensure
        file.close
      end
    end
  end

  def self.zip(zip_file, file_hash)
    FileUtils.rm_rf zip_file if File.exist? zip_file
    Zip::File.open(zip_file, Zip::File::CREATE) do |zip|
      file_hash.each do |source, destination|
        zip.add(destination, source)
      end
    end
  end
end
