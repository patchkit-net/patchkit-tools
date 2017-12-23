module FileHelper
  # Lists all files in directory and returns their relative path
  def self.list_relative(dir)
    dir = dir.gsub('\\','/')
    dir_path = Pathname.new(dir)
    all_files = Dir.glob("#{dir}/**/*", File::FNM_DOTMATCH)
    all_files = all_files.reject do |p|
      p == '.' || p == '..' || p.end_with?('/.') || p.end_with?('/..')
    end

    all_files.map do |e|
      Pathname.new(e).relative_path_from(dir_path).to_s
    end
  end

  def self.only_zip_file_in_directory(dir)
    l = list_relative(dir)
    l.count == 1 && l[0].end_with?(".zip")
  end
end
