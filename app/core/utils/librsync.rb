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

  def self.windows?
    ((/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil)
  end

  def self.windows_32bit?
    windows? && bits == 32
  end

  def self.windows_64bit?
    windows? && bits == 64
  end

  def self.mac_osx?
    ((/darwin/ =~ RUBY_PLATFORM) != nil)
  end

  def self.mac_osx_32bit?
    mac_osx? && bits == 32
  end

  def self.mac_osx_64bit?
    mac_osx? && bits == 64
  end

  def self.linux?
    !windows? && !mac_osx?
  end

  def self.linux_32bit?
    linux? && bits == 32
  end

  def self.linux_64bit?
    linux? && bits == 64
  end

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
      "x86_64/librsync.so"
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
      path = File.join("#{search_dir}", lib_name)
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
end
