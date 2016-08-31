require 'optparse'
require 'ostruct'

# Helpers for writing PatchKit Tools
module PatchKitTools
  # Helper class for parsing command line options
  class Options
    def initialize(program_name, program_description, *program_usages)
      @source = OpenStruct.new
      @program_name = program_name
      @program_description = program_description
      @program_usages = program_usages
    end

    # Parse command line options
    def parse(args)
      @opt_parser = OptionParser.new do |opts|
        opts.banner = "patchkit-tools #{@program_name}"

        opts.separator ""

        opts.separator "Description:"

        opts.separator opts.summary_indent+@program_description

        opts.separator ""

        opts.separator "Usage:"

        for program_usage in @program_usages
          opts.separator opts.summary_indent+"patchkit-tools #{@program_name} #{program_usage}"
        end

        opts.separator opts.summary_indent+"patchkit-tools #{@program_name} --help"

        opts.separator ""

        opts.separator "Help"

        opts.on("-h", "--help", "outputs a usage message and exit") do
          puts opts
          exit
        end

        opts.separator ""

        yield opts

        opts.separator ""
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
