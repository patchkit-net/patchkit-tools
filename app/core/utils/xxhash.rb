require 'fiddle'
require 'fiddle/import'
require_relative 'platform'

module PatchKitTools
  module Xxhash
    extend Fiddle::Importer
    extend PatchKitTools::Platform

    def self.library_path
      if linux_aarch64?
         'app/bin/aarch64/libxxhash_c_library.so'
       elsif linux_64bit?
         'app/bin/x86_64/libxxhash_c_library.so'
       elsif mac_osx_64bit?
         'app/bin/x86_64/libxxhash_c_library.so'
       elsif windows_64bit?
         File.expand_path('../../bin/x86_64/xxhash_c_library.dll', __dir__)
       else
         raise "Unsupported platform: #{RUBY_PLATFORM}"
       end

    end

    dlload library_path

    extern 'unsigned long long hash_file(const char*, unsigned int, unsigned int)'

    XXH32 = 32
    XXH64 = 64
    XXH3 = 3

    def self.hash(path, algorithm, seed = 0)
      alg = case algorithm
            when :xxh32 then XXH32
            when :xxh64 then XXH64
            when :xxh3  then XXH3
            else
              raise ArgumentError, "Unsupported algorithm: #{algorithm}"
            end

      hash_file(path, alg, seed)
    end
  end
end