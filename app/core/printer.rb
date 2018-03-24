module PatchKitTools
  module Printer
    class << self
      attr_accessor :quiet
    end

    def puts(str = nil)
      Kernel.puts str unless Printer.quiet
    end
  end
end
