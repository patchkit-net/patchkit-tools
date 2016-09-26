require 'optparse'
require 'ostruct'

module PatchKitTools
  def self.execute_tool(tool)
    begin
      tool.parse_options
      tool.execute
      puts "Done!"
      exit true
    rescue => error
      puts "ERROR: #{error}"

      if PatchKitConfig.debug
        puts error.backtrace
      end

      exit false
    end
  end

  # Base class for every tool
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
        opts.banner = ""

        opts.separator "patchkit-tools #{@program_name}"

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

    def ask(question)
      print "#{question}: "
      return STDIN.gets.strip
    end

    def ask_yes_or_no(question, default)
      default.downcase!
      result = ask(question + " " + (default == "y" ? "(Y/n)" : (default == "n" ? "(y/N)" : "(y/n)")))
      result.downcase!

      if((default == "y" || default == "n") && (result.nil? || result.empty?))
        result = default
      end

      if(result == "y")
        return true
      elsif(result =="n")
        return false
      end

      puts "Invaild answer - #{result}. Try again."
      ask_yes_or_no(question, default)
    end

    def ask_if_option_missing!(name)
      if eval(name).nil?
        result = ask("Please enter --#{get_argument_name(name)}")
        eval("self.#{name} = \"#{result}\"")
      end

      check_if_option_exists(name)
    end

    def check_if_option_exists(name)
      raise "[--#{get_argument_name(name)}] Missing argument" if eval(name).nil? || (eval(name).is_a?(String) && eval(name).empty?)
    end

    def check_if_valid_option_value(name, possible_values)
      raise "[--#{get_argument_name(name)}] Invalid argument value" unless possible_values.include? eval(name)
    end

    def check_if_option_directory_exists(name)
      check_if_option_exists(name)
      raise "[--#{get_argument_name(name)}] Directory doesn't exists - #{eval(name)}" unless File.directory?(eval(name))
    end

    def check_if_option_file_exists_and_readable(name)
      check_if_option_exists(name)
      raise "[--#{get_argument_name(name)}] File doesn't exists - #{eval(name)}" unless File.file?(eval(name))
      raise "[--#{get_argument_name(name)}] File isn't readable - #{eval(name)}" unless File.readable?(eval(name))
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
