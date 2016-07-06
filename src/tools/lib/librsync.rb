require 'fiddle'
require 'fiddle/import'

# Binding of librsync library
module Librsync
  private

  # Helper fuctions for choosing right library file

  def self.is_windows?
    ((/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil)
  end

  def self.is_windows_32bit?
    (is_windows? && !is_windows_64bit?)
  end

  def self.is_windows_64bit?
    (is_windows? && ENV.has_key?('ProgramFiles(x86)'))
  end

  def self.is_mac_osx?
    (/darwin/ =~ RUBY_PLATFORM) != nil
  end

  def self.is_mac_osx_32bit?
    return is_mac_osx? && 1.size == 4
  end

  def self.is_mac_osx_64bit?
    return is_mac_osx? && 1.size == 8
  end

  def self.is_linux?
    return !is_windows? && !is_mac_osx?
  end

  def self.is_linux_32bit?
    return is_mac_osx? && 1.size == 4
  end

  def self.is_linux_64bit?
    return is_mac_osx? && 1.size == 8
  end

  def self.get_lib_name
    if self.is_windows_32bit?
      raise "Unsupported librsync platform - Windows (32-bit)"
    elsif self.is_windows_64bit?
      "lib/rsync-x64.dll"
    elsif self.is_mac_osx_32bit?
      raise "Unsupported librsync platform - Mac OSX (32-bit)"
    elsif self.is_mac_osx_64bit?
      raise "Unsupported librsync platform - Mac OSX (64-bit)"
    elsif self.is_linux_32bit?
      raise "Unsupported librsync platform - Mac OSX (32-bit)"
    elsif self.is_linux_64bit?
      raise "Unsupported librsync platform - Mac OSX (64-bit)"
    else
      raise "Unsupported librsync platform - Unknown"
    end
  end

  public

  extend Fiddle::Importer

  # Load library
  dlload self.get_lib_name

  # rdiff delta
  extern 'int rs_rdiff_delta(char*, char*, char*)'
end
