require 'stringio'
require_relative 'windows_long_path'

module PatchKitTools

  # Verifies if a delta file is copy and zero-offset only. If true, this means that the delta file represents an unchanged file
  class DeltaFileVerifier
    DELTA_MAGIC = 0x72730236

    def initialize(file_path)
      @file_path = file_path
      @only_zero_offsets = true
    end

    def self.verify(file_path)
      new(file_path).verify
    end

    def verify
      File.open(WindowsLongPath.fix(@file_path), 'rb') do |file|
        verify_magic_number(file)
        verify_commands(file)
      end
      @only_zero_offsets
    rescue StandardError => e
      puts "Verification failed: #{e.message} on #{@file_path}"
      false
    end

    private

    def verify_magic_number(file)
      magic = file.read(4).unpack('N')[0]
      raise "Invalid magic number" unless magic == DELTA_MAGIC
    end

    def verify_commands(file)
      while !file.eof?
        command = file.read(1).ord
        # p command.to_s(16)
        case command
        when 0x45..0x54
          verify_copy_command(file, command)
        when 0x41..0x44
          @only_zero_offsets = false
          break
        when 0
          break  # End command
        else
          raise "Invalid command byte: #{command}"
        end
      end
    end

    def verify_copy_command(file, command)
      arg1_len, arg2_len = command_arg_lengths(command)
      start = read_integer(file, arg1_len)
      length = read_integer(file, arg2_len)
      # puts "Copy command: start=#{start}, length=#{length}"

      @only_zero_offsets = false if start != 0
    end

    def command_arg_lengths(command)
      case command
      when 0x45 then [1, 1]
      when 0x46 then [1, 2]
      when 0x47 then [1, 4]
      when 0x48 then [1, 8]
      when 0x49 then [2, 1]
      when 0x4A then [2, 2]
      when 0x4B then [2, 4]
      when 0x4C then [2, 8]
      when 0x4D then [4, 1]
      when 0x4E then [4, 2]
      when 0x4F then [4, 4]
      when 0x50 then [4, 8]
      when 0x51 then [8, 1]
      when 0x52 then [8, 2]
      when 0x53 then [8, 4]
      when 0x54 then [8, 8]
      else
        raise "Invalid command: #{command}"
      end
    end

    def read_integer(file, byte_count)
      bytes = file.read(byte_count)
      # puts "Read bytes (hex): #{bytes.unpack('H*').first}"

      bytes.unpack("C#{byte_count}").reduce(0) { |acc, byte| (acc << 8) | byte }
    end
  end
end