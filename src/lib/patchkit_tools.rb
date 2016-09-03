require 'optparse'
require 'ostruct'

# Helpers for writing PatchKit Tools
module PatchKitTools
  def safe_execute
    begin
      yield
    rescue => error
      puts "ERROR: #{error}"
      exit
    end
  end

  # Base class for tools
  class Tool
    def initialize(program_name, program_description, *program_usages)
      @source = OpenStruct.new
      @program_name = program_name
      @program_description = program_description
      @program_usages = program_usages
    end

    # Parse options from command line
    def parse_options
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

        opts.separator ""
      end

      @opt_parser.parse!(ARGV)
    end

    def error(description)
      puts "ERROR: #{description}"
      puts ""
      puts @opt_parser.help
      exit false
    end

    def check_if_option_exists(name)
      error_argument "Missing argument --#{get_argument_name(name)}" if eval(name).nil?
    end

    def check_if_argument_exists_or_read!(name)
      if !$silent && eval(name).nil?
        print "Please enter --#{get_argument_name(name)}: "
        eval("#{name} = #{gets.strip}")
      end

      check_if_argument_exists
    end

    def check_if_valid_argument_value(name, possible_values)
      error_argument "Invalid argument value --#{get_argument_name(name)}" unless possible_values.include? eval(name)
    end

    def check_if_directory_exists(name)
      check_if_argument_exists(name)
      error_argument "Directory doesn't exists --#{get_argument_name(name)}=#{eval(name)}" unless File.directory?(eval(name))
    end

    def check_if_file_exists(name)
      check_if_argument_exists(name)
      error_argument "File doesn't exists --#{get_argument_name(name)}=#{eval(name)}" unless File.file?(eval(name))
    end

    # Alias to @source
    def method_missing(method, *args, &block)
      @source.send(method, *args, &block)
    end

  private
    def get_argument_name(name)
      name.gsub('_','')
    end
  end
end
