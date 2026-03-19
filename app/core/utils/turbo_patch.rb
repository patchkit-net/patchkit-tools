require 'fiddle'
require_relative 'platform'

module PatchKitTools
  module TurboPatch
    include PatchKitTools::Platform
    extend self

    def load_library
      lib_path = if linux_aarch64?
                   'app/bin/aarch64/libturbopatch.so'
                 elsif linux_64bit?
                   'app/bin/x86_64/libturbopatch.so'
                 elsif mac_osx_64bit?
                   'app/bin/x86_64/libturbopatch.so'
                 elsif windows_64bit?
                   File.expand_path("../../bin/x86_64/turbopatch.dll", __dir__)
                 else
                   raise "Unsupported platform: #{RUBY_PLATFORM}"
                 end

      Fiddle.dlopen(lib_path)
    end

    LIB = load_library

    # Binding the external functions
    DELTA_FUNC = Fiddle::Function.new(
      LIB['tp_delta2'],
      [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_LONG_LONG],
      Fiddle::TYPE_INT
    )

    PATCH_FUNC = Fiddle::Function.new(
      LIB['tp_patch'],
      [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP],
      Fiddle::TYPE_INT
    )

    # Ruby-friendly wrappers
    def delta(old_sig_path, new_sig_path, new_file_path, file_path, block_size)

      result = DELTA_FUNC.call(
        Fiddle::Pointer[old_sig_path],
        Fiddle::Pointer[new_sig_path],
        Fiddle::Pointer[new_file_path],
        Fiddle::Pointer[file_path],
        block_size
      )
      result
    end

    def patch(source_path, delta_path)
      PATCH_FUNC.call(
        Fiddle::Pointer[source_path],
        Fiddle::Pointer[delta_path]
      )
    end
  end
end