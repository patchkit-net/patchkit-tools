require 'zip'

def unzip(zip_file, destination_path)
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
