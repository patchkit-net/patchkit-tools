require 'zip'
require_relative 'pack1_packer'
require_relative 'sha1_io_proxy'
require_relative 'windows_long_path'

# Packs the file, generates SHA1 and makes it available
class Packer
  def initialize(algorithm:, key: nil)
    raise "Algorithm not specified" unless algorithm
    raise "Unknown algorithm: #{algorithm}" unless %i[zip pack1].include?(algorithm.to_sym)

    @algorithm = algorithm.to_sym
    @key = key

    raise "Key must be set for pack1" if algorithm.to_sym == :pack1 && key.nil?
  end

  def self.open(file, algorithm:, key: nil, &block)
    new(algorithm: algorithm, key: key).open(file, &block)
  end
  def open(file)
    @file = file
    begin

      @processor =
        case @algorithm
        when :zip
          # does not open io for zip, because it can result in permission denied on zip close on Windows machines

          raise "expect one file path" unless file.is_a?(String)
          Zip::File.open(@file, true)
        when :pack1
          @io = File.open(WindowsLongPath.fix(file.is_a?(String) ? file : file[0]), "wb")
          @io_proxy = PatchKitTools::SHA1IOProxy.new(@io)

          raise "expect array of two files" unless file.is_a?(Array) && file.size == 2
          packer = Pack1Packer.new
          packer.encrypted_key = @key
          packer
        else
          raise "Unknown algorithm: #{@algorithm}"
        end

      if block_given?
        begin
          yield self
        ensure
          close
        end
      end
    ensure
      @io_proxy&.close
      @io&.close
    end

    self
  end

  def sha1
    # ZIP writer jumps back and forth, therefore we can't calculate the SHA1 during the write.
    # Normally, we could calculate it on close, but let's not do it for now as SHA1 are not needed in every case.
    # This is bound to be changed, but then we might switch to TAR packages.
    if @algorithm != :zip
      @io_proxy&.sha1
    end
  end

  def add(entry_name:, source_file_path:)
    case @algorithm
    when :zip
      @processor.add(entry_name, WindowsLongPath.fix(source_file_path))
    when :pack1
      @processor.add_file(source_file_path, entry_name)
    end
  end

  def close
    case @algorithm
    when :zip
      @processor.close
    when :pack1
      raise "@io_proxy is nil" if @io_proxy.nil?

      @processor.pack(@io_proxy, @file[1])
    end
  end
end