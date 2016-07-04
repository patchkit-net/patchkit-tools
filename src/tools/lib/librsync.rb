require 'fiddle'
require 'fiddle/import'

module Librsync
  private

  def self.get_lib_name
    if (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
      "lib/rsync.dll"
    elsif (/darwin/ =~ RUBY_PLATFORM) != nil
      "lib/rsync.so"
    else
      "lib/rsync.bundle"
    end
  end

  public

  extend Fiddle::Importer
  dlload self.get_lib_name
  #extern 'void* rs_file_open(char*, char*)'
  #extern 'int rs_file_close(void*)'

  extern 'int rs_rdiff_delta(char*, char*, char*)'

  #ffi_lib ["lib/rsync", "lib/rsync.so", "lib/rsync.bundle"]

  #attach_function :rs_file_open, [:string, :string], :pointer
  #attach_function :rs_file_close, [:pointer], :int
  #attach_function :rs_delta_file, [:pointer, :pointer, :pointer, :pointer], :int
  #attach_function :rs_loadsig_file, [:pointer, :pointer, :pointer], :int
  #attach_function :rs_build_hash_table, [:pointer], :int
  #attach_function :rs_free_sumset, [:pointer], :void
end
