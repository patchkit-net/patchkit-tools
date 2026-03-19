module PatchKitTools
  module Platform
    # Helper functions for choosing right library file

    # Based on https://github.com/rdp/os/blob/953bf8d646f8f6ae2a3609f2a6e21b508e6a021f/lib/os.rb
    def bits
      host_cpu = RbConfig::CONFIG['host_cpu']
      host_os = RbConfig::CONFIG['host_os']
      if host_cpu =~ /_64$/ || host_cpu == 'x64' || RUBY_PLATFORM =~ /x86_64/ || RUBY_PLATFORM =~ /\bx64\b/
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

    def x86?
      cpu = RbConfig::CONFIG['host_cpu'].downcase
      cpu.include?('x86') || cpu == 'x64'
    end

    def aarch64?
      RbConfig::CONFIG['host_cpu'].downcase.include?('aarch64')
    end

    def windows?
      ((/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil)
    end

    def windows_32bit?
      windows? && bits == 32
    end

    def windows_64bit?
      windows? && bits == 64
    end

    def mac_osx?
      ((/darwin/ =~ RUBY_PLATFORM) != nil)
    end

    def mac_osx_32bit?
      mac_osx? && bits == 32
    end

    def mac_osx_64bit?
      mac_osx? && bits == 64
    end

    def linux?
      !windows? && !mac_osx?
    end

    def linux_32bit?
      linux? && bits == 32 && x86?
    end

    def linux_64bit?
      linux? && bits == 64 && x86?
    end

    def linux_aarch64?
      linux? && bits == 64 && aarch64?
    end
  end
end