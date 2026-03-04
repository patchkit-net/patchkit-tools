require 'fileutils'

module WindowsLongPath
  LONG_PATH_PREFIX = '\\\\?\\'

  # Converts a path to a Windows extended-length path (\\?\) that supports
  # paths up to ~32,767 characters, bypassing the 260-char MAX_PATH limit.
  #
  # Rules:
  # - Only applied on Windows
  # - Must be absolute path with backslashes (no forward slashes after prefix)
  # - No . or .. resolution after prefix, so we normalize first
  # - Idempotent: won't double-prefix
  def self.fix(path)
    return path unless windows?
    return path if path.start_with?(LONG_PATH_PREFIX)

    full_path = File.expand_path(path).gsub('/', '\\')
    "#{LONG_PATH_PREFIX}#{full_path}"
  end

  # Ruby's FileUtils.rm_rf doesn't work with long paths on Windows because
  # it uses Dir internally which doesn't support \\?\ prefix.
  # Falls back to Windows 'rd /s /q' command for directories.
  def self.safe_rm_rf(path)
    return FileUtils.rm_rf(path) unless windows?

    fixed = fix(path)

    if File.directory?(fixed)
      # rd requires the raw path without \\?\ prefix
      raw_path = fixed.sub(/\A#{Regexp.escape(LONG_PATH_PREFIX)}/, '')
      system("cmd.exe", "/c", "rd", "/s", "/q", raw_path)
    elsif File.exist?(fixed)
      File.delete(fixed)
    end
  end

  # Returns the Windows 8.3 short path for a given path.
  # This is needed when passing paths to native C libraries (via FFI/Fiddle)
  # because standard C fopen() doesn't support \\?\ prefix or paths > 260 chars,
  # but it DOES support 8.3 short paths which are always under 260 chars.
  #
  # If the file doesn't exist yet (e.g., output files), it shortens the parent
  # directory and appends the filename.
  def self.short_path(path)
    return path unless windows?

    @get_short_path_name ||= begin
      require 'fiddle'
      require 'fiddle/import'
      kernel32 = Fiddle.dlopen('kernel32.dll')
      Fiddle::Function.new(
        kernel32['GetShortPathNameA'],
        [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT],
        Fiddle::TYPE_INT
      )
    end

    abs_path = File.expand_path(path).gsub('/', '\\')
    buf = "\0" * 32767
    len = @get_short_path_name.call(abs_path, buf, buf.size)

    if len > 0
      buf[0, len]
    elsif File.exist?(fix(File.dirname(path)))
      # File doesn't exist yet — shorten parent directory and append filename
      short_dir = short_path(File.dirname(path))
      File.join(short_dir, File.basename(path)).gsub('/', '\\')
    else
      # If short path generation fails (e.g., 8.3 names disabled), return original
      path
    end
  end

  def self.windows?
    (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
  end
end
