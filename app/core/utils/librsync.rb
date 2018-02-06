require 'rubygems'
require 'bundler/setup'
require 'fiddle'
require 'fiddle/import'
require 'rbconfig'

# Binding of librsync library
module Librsync
  private

  # Helper fuctions for choosing right library file

  # Based on https://github.com/rdp/os/blob/953bf8d646f8f6ae2a3609f2a6e21b508e6a021f/lib/os.rb
  def self.bits
    host_cpu = RbConfig::CONFIG['host_cpu']
    host_os = RbConfig::CONFIG['host_os']
    if host_cpu =~ /_64$/ || RUBY_PLATFORM =~ /x86_64/
      64
    elsif RUBY_PLATFORM == 'java' && ENV_JAVA['sun.arch.data.model'] # "32" or "64":http://www.ruby-forum.com/topic/202173#880613
      ENV_JAVA['sun.arch.data.model'].to_i
    elsif host_cpu == 'i386'
      32
    elsif host_os =~ /32$/ # mingw32, mswin32
      32
    else # cygwin only...I think
      1.size == 8 ? 64 : 32
    end
  end

  def self.is_windows?
    ((/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil)
  end

  def self.is_windows_32bit?
    is_windows? && bits == 32
  end

  def self.is_windows_64bit?
    is_windows? && bits == 64
  end

  def self.is_mac_osx?
    ((/darwin/ =~ RUBY_PLATFORM) != nil)
  end

  def self.is_mac_osx_32bit?
    is_mac_osx? && bits == 32
  end

  def self.is_mac_osx_64bit?
    is_mac_osx? && bits == 64
  end

  def self.is_linux?
    !is_windows? && !is_mac_osx?
  end

  def self.is_linux_32bit?
    is_linux? && bits == 32
  end

  def self.is_linux_64bit?
    is_linux? && bits == 64
  end

  def self.get_lib_name
    if self.is_windows_32bit?
      "x86/rsync.dll"
    elsif self.is_windows_64bit?
      "x86_64/rsync.dll"
    elsif self.is_mac_osx_32bit?
      raise "Unsupported librsync platform - Mac OSX (32-bit)"
    elsif self.is_mac_osx_64bit?
      "x86_64/rsync.bundle"
    elsif self.is_linux_32bit?
      "x86/librsync.so"
    elsif self.is_linux_64bit?
      "x86_64/librsync.so"
    else
      raise "Unsupported librsync platform - Unknown"
    end
  end

  def self.get_lib_path
    return "#{File.dirname(__FILE__)}/../../bin/#{get_lib_name}"
  end

  public

  extend Fiddle::Importer

  # Load library
  dlload self.get_lib_path

  # rdiff delta
  extern 'int rs_rdiff_delta(char*, char*, char*)'
end
