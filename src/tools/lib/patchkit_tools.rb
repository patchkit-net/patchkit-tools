require 'optparse'
require 'ostruct'

module PatchKitTools
  class Options
    def initialize
      @source = OpenStruct.new
    end

    def parse(name, args)
      @opt_parser = OptionParser.new do |opts|
        opts.banner = "Usage: patchkit-tools #{name} [options]"

        opts.separator ""

        opts.separator "Specific options:"

        yield opts

        opts.separator ""

        opts.separator "Common options:"

        opts.on_tail("-h", "--help", "show this message") do
          puts opts
          exit
        end
      end
      @opt_parser.parse!(args)
    end

    def error(description)
      puts "ERROR: #{description}"
      puts ""
      puts @opt_parser.help
      exit
    end

    def error_argument_missing(name)
      error "Missing argument --#{name}"
    end

    def error_invalid_argument_value(name)
      error "Invalid argument value --#{name}"
    end

    def method_missing(method, *args, &block)
      @source.send(method, *args, &block)
    end
  end
end
