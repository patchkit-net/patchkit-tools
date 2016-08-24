require 'optparse'
require 'ostruct'

# Helpers for writing PatchKit Tools
module PatchKitTools
  # Helper class for parsing command line options
  class Options
    def initialize(program_name, program_description)
      @source = OpenStruct.new
      @program_name = program_name
      @program_description = program_description
    end

    # Parse command line options
    def parse(args)
      @opt_parser = OptionParser.new do |opts|
        opts.banner = "Usage: patchkit-tools #{@program_name} [options]"

        opts.separator ""

        opts.separator @program_description

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

    # Displays error
    def error(description)
      puts "ERROR: #{description}"
      puts ""
      puts @opt_parser.help
      exit
    end

    # Displays missing argument error
    def error_argument_missing(name)
      error "Missing argument --#{name}"
    end

    # Displays invaild argument value error
    def error_invalid_argument_value(name)
      error "Invalid argument value --#{name}"
    end

    # Alias to @source
    def method_missing(method, *args, &block)
      @source.send(method, *args, &block)
    end
  end
end
