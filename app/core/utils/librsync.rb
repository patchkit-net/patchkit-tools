require 'rubygems'
require 'bundler/setup'
require 'fiddle'
require 'fiddle/import'
require 'rbconfig'
require_relative 'platform'

# Binding of librsync library
module Librsync
  extend PatchKitTools::Platform

  private

  def self.lib_name
    if windows_32bit?
      "x86/rsync.dll"
    elsif windows_64bit?
      "x86_64/rsync.dll"
    elsif mac_osx_32bit?
      raise "Unsupported librsync platform - Mac OSX (32-bit)"
    elsif mac_osx_64bit?
      "x86_64/rsync.bundle"
    elsif linux_32bit?
      "x86/librsync.so"
    elsif linux_64bit?
      "x86_64/librsync.so.2.3.2"
    elsif linux_aarch64?
      "aarch64/librsync.so.2.0.1"
    else
      raise "Unsupported librsync platform - Unknown"
    end
  end

  def self.lib_path
    search_dirs = [
      "#{File.dirname(__FILE__)}/../../",
      "#{File.dirname(__FILE__)}/../../bin"
    ]

    search_dirs.each do |search_dir|
      path = File.expand_path(File.join(search_dir, lib_name))
      return path if File.exist? path
    end

    raise "Cannot find library: #{lib_name}, search_dirs: #{search_dirs}"
  end

  public

  extend Fiddle::Importer

  # Load library
  dlload lib_path

  # rdiff delta
  extern 'int rs_rdiff_delta(char*, char*, char*)'

  # basis_name, sig_name, block size
  extern 'int rs_rdiff_sig(char*, char*, size_t)'
end
