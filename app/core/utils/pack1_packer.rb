require 'openssl'
require 'digest'
require 'json'

##
# Packer for packing files in encrypted and random-read friendly manner.
# All files are separately:
# 1. Packed using gzip algorithm
# 2. Encrypted using AES-256-CBC
# 3. Merged into a single file
#
# File merging is done without any information about the file structure.
# This information is stored in a separate meta file.
#
# The reason why this is separate file dictated by packing optimization
# procedure. We cannot tell how big the file is until we zip and encrypt
# it. But then it's too late to write a header.
class Pack1Packer
  BUFFER_SIZE = 1024 * 1024 * 5
  MAGIC = "Pack1\x01\x02\x03\x04".freeze

  def initialize(compression_method: :gzip)
    @files = []

    @alg = '256-CBC'

    @cipher = OpenSSL::Cipher::AES.new(@alg)
    @cipher.encrypt
    @iv = @cipher.random_iv

    @compression_method = compression_method&.to_sym
    @compression_method = :xz if @compression_method == :lzma2 # alias
  end

  def key=(key)
    @cipher.key = encrypt_password(key)
  end

  def encrypted_key=(key)
    @cipher.key = key
  end

  def add_file(source, name)
    f = FileInfo.new
    f.ftype = :regular
    f.name = name
    f.source = source
    f.mode = format("%o", File.stat(source).mode)
    @files << f
  end

  def add_directory(name)
    f = FileInfo.new
    f.ftype = :directory
    f.name = name
    f.mode = format("%o", 0o100755)
    @files << f
  end

  def add_symlink(target, name)
    f = FileInfo.new
    f.ftype = :symlink
    f.name = name
    f.target = target
    @files << f
  end

  def add_directory_contents(directory)
    directory_path = Pathname.new(directory)
    Dir.glob("#{directory}/**/*").each do |file|
      relative = Pathname.new(file).relative_path_from(directory_path).to_s
      if File.directory? file
        add_directory(relative)
      elsif File.symlink? file
        add_symlink(File.readlink(file), relative)
      else
        add_file(file, relative)
      end
    end
  end

  def pack(archive, meta)
    write_archive(archive)
    write_meta_file(meta)
  end

  private

    def write_archive(archive)
      @offsets = {}
      @sizes = {}
      offset = 0

      io = if archive.is_a?(String)
        File.open(archive, "wb")
      else
        archive
      end

      begin
        io.write(MAGIC)
        offset += MAGIC.bytesize

        @files.each do |file_info|
          next if file_info.ftype != :regular

          file_info.offset = offset

          bytes_read, bytes_written = write_single(file_info.source, io)
          offset += bytes_written

          file_info.size = bytes_written
          file_info.usize = bytes_read
        end
      ensure
        io.close if archive.is_a?(String)
      end
    end

    def write_single(source, output_stream)
      read = 0
      written = 0

      File.open(source) do |f|
        until f.eof?
          bytes = f.read(BUFFER_SIZE)
          read += bytes.bytesize

          bytes = compress(bytes, final: f.eof?)
          bytes = encrypt(bytes, final: f.eof?)

          output_stream << bytes
          written += bytes.bytesize
        end
      end

      [read, written]
    end

    def write_meta_file(path)
      files = @files.map do |f|
        {
          name: f.name,
          type: f.ftype,
          target: f.target,
          mode: f.mode,
          offset: f.offset,
          size: f.size,
          usize: f.usize
        }
      end

      json = {
        version: '1.1',
        encryption: 'aes',
        compression: @compression_method,
        iv: [@iv].pack('m').strip,
        files: files
      }

      File.write(path, JSON.generate(json))
    end

    def compress(data, **args)
      @compressor_io ||= StringIO.new
      @compressor ||= new_compressor(@compressor_io)
      @compressor << data
      @compressor.flush if @compressor.respond_to? :flush

      # if gzip is to be closed, it has to be before reading the string
      # gzip.flush is just not enough
      if args[:final]
        @compressor.finish if @compressor.respond_to? :finish
        @compressor.close
      end
      data = @compressor_io.string

      @compressor_io.string = ''

      if args[:final]
        @compressor = nil
        @compressor_io = nil
      end

      data
    end

    def new_compressor(io)
      case @compression_method
      when :gzip
        Zlib::GzipWriter.new(io)
      else
        raise "unsupported compression method: #{@compression_method}"
      end
    end

    def encrypt(data, **args)
      ret =
        if !data.empty?
          @cipher.update(data)
        else
          ''
        end

      if args[:final]
        ret << @cipher.final
        @cipher.reset
      end

      ret
    end

    def encrypt_password(pass)
      Digest::SHA256.digest pass
    end

    class FileInfo
      attr_accessor :name
      attr_accessor :ftype # :regular, :directory, :symlink
      attr_accessor :source # for regular files
      attr_accessor :target # for symlinks
      attr_accessor :offset # for regular files
      attr_accessor :size # for regular files
      attr_accessor :usize # for regular files
      attr_accessor :mode # for regular files and directories
    end
end # class Packer
