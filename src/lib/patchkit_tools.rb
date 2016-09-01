require 'optparse'
require 'ostruct'

# Helpers for writing PatchKit Tools
module PatchKitTools
  # Helper class for parsing command line options
  class Tool
    def initialize(program_name, program_description, *program_usages)
      @source = OpenStruct.new
      @program_name = program_name
      @program_description = program_description
      @program_usages = program_usages
    end

    # Parse command line options
    def parse_arguments
      # Default argument values
      self.silent = false

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

        yield opts

        opts.separator ""

        opts.separator "Common"

        opts.on("-h", "--help", "outputs a usage message and exit") do
          puts opts
          exit
        end

        opts.on("-x", "--silent", "hides all information messages") do
          self.silent = true
        end

        opts.separator ""
      end

      @opt_parser.parse!($patchkit_tools_argv.nil? ? ARGV : $patchkit_tools_argv)
    end

    def print_info(info)
      puts info unless self.silent
    end

    def print_data(data)
      puts data
    end

    def error_argument(description)
      puts "ERROR: #{description}"
      puts ""
      puts @opt_parser.help
      exit
    end

    def check_if_argument_exists(name)
      error_argument "Missing argument --#{get_argument_name(name)}" if eval(name).nil?
    end

    def check_if_argument_exists_or_read!(name)
      if !self.silent && eval(name).nil?
        print "Please enter --#{get_argument_name(name)}: "
        eval("#{name} = #{gets.strip}")
      end

      check_if_argument_exists
    end

    def check_if_valid_argument_value(name, possible_values)
      error_argument "Invalid argument value --#{get_argument_name(name)}" unless possible_values.include? eval(name)
    end

    def check_if_directory_exists(name)
      error_argument "Directory doesn't exists --#{get_argument_name(name)}=#{path}" if File.directory? eval(name)
    end

    def check_if_file_exists(name)
      error_argument "File doesn't exists --#{get_argument_name(name)}=#{path}" if File.file? eval(name)
    end

    # Alias to @source
    def method_missing(method, *args, &block)
      @source.send(method, *args, &block)
    end

    def start_other_tool(tool_name, *args)
      $patchkit_tools_argv = args

      previous_stdout = $stdout
      output = StringIO.new
      $stdout = output

      load "#{File.dirname($0)}/#{tool_name}.rb"

      $patchkit_tools_argv = nil
      $stdout = previous_stdout

      output.string
    end

  private
    def get_argument_name(name)
      name.gsub('_','')
    end
  end
end
