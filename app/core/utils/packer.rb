require 'zip'
require_relative 'pack1_packer'
require_relative 'sha1_io_proxy'

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
    @io = File.open(file.is_a?(String) ? file : file[0], "wb")
    @io_proxy = PatchKitTools::SHA1IOProxy.new(@io)
    begin

      @processor =
        case @algorithm
        when :zip
          raise "expect one file path" unless file.is_a?(String)
          Zip::File.open(@io_proxy)
        when :pack1
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
      @io_proxy.close
      @io.close
    end

    self
  end

  def sha1
    @io_proxy.sha1
  end

  def add(entry_name:, source_file_path:)
    case @algorithm
    when :zip
      @processor.add(entry_name, source_file_path)
    when :pack1
      @processor.add_file(source_file_path, entry_name)
    end
  end

  def close
    case @algorithm
    when :zip
      @processor.close
    when :pack1
      @processor.pack(@io_proxy, @file[1])
    end
  end
end