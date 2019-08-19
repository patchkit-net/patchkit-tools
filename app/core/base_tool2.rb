require_relative 'printer'

# Base class for every tool

module PatchKitTools
  class BaseTool2
    include Printer

    attr_reader :host
    attr_reader :https

    def initialize(argv, program_name, program_description, *program_usages)
      @program_name = program_name
      @program_description = program_description
      @program_usages = program_usages

      @opts_defined = []
      @opts_used = []
      @opts_required = []
      @argv = argv
    end

    # Parse options from command line
    def parse_options
      @opt_parser = OptionParser.new do |opts|
        opts.banner = ""

        opts.separator "patchkit-tools #{@program_name}"
        opts.separator ""
        opts.separator "Description:"
        opts.separator opts.summary_indent + @program_description
        opts.separator ""
        opts.separator "Usage:"

        @program_usages.each do |program_usage|
          opts.separator opts.summary_indent + "patchkit-tools #{@program_name} #{program_usage}"
        end

        opts.separator opts.summary_indent + "patchkit-tools #{@program_name} --help"
        opts.separator ""
      end

      # opts.separator "Mandatory"
      # required_params(opts)

      # opts.separator ""
      # opts.separator "Optional"
      # optional_params(opts)

      yield @opt_parser

      @opt_parser.separator ""
      @opt_parser.separator "Common"

      unless @opts_defined.include? :host
        @opt_parser.on('--host <host>', 'Hostname (format: patchkit.net)') do |host|
          @host = host
        end
      end

      unless @opts_defined.include? :https
        @opt_parser.on('--https <true|false>', 'Use HTTPS (false)') do |host|
          @host = host
        end
      end

      @opt_parser.on("-h", "--help", "outputs a usage message and exit") do
        puts @opt_parser
        exit
      end

      @opt_parser.separator ""
      @opt_parser.parse!(@argv)

      @opts_required.each do |opt|
        raise CommandLineError, "Missing required option --#{opt}" unless @opts_used.include? opt
      end

      PatchKitAPI.api_key = @api_key
    end

    def ask(question)
      print "#{question}: "
      STDIN.gets.strip
    end

    def ask_yes_or_no(question, default)
      default.downcase!
      result = ask(question + " " + (default == "y" ? "(Y/n)" : (default == "n" ? "(y/N)" : "(y/n)")))
      result.downcase!

      if ((default == "y" || default == "n") && (result.nil? || result.empty?))
        result = default
      end

      if result == "y"
        return true
      elsif result == "n"
        return false
      end

      puts "Invaild answer - #{result}. Try again."
      ask_yes_or_no(question, default)
    end

    def ask_if_option_missing!(name)
      if instance_variable_get("@#{name}").nil?
        result = ask("Please enter --#{argument_name(name)}")
        instance_variable_set("@#{name}", result)

        PatchKitAPI.api_key = @api_key if name.to_s == 'api_key'
      end

      check_if_option_exists(name)
    end

    # Deprecated
    def check_if_option_exists(*names)
      names.each do |name|
        value = instance_variable_get("@#{name}")

        if value.nil? || (value.is_a?(String) && value.empty?)
          raise CommandLineError, "[--#{argument_name(name)}] Missing argument"
        end
      end
    end

    def check_if_valid_option_value(name, possible_values)
      value = instance_variable_get("@#{name}")

      unless possible_values.include? value
        raise CommandLineError, "[--#{argument_name(name)}] Invalid argument value"
      end
    end

    def check_if_option_directory_exists(name)
      check_if_option_exists(name)

      value = instance_variable_get("@#{name}")

      unless File.exist?(value)
        raise CommandLineError, "[--#{argument_name(name)}] Directory doesn't exists - #{value}"
      end

      unless File.directory?(value)
        raise CommandLineError, "[--#{argument_name(name)}] Excepted argument to be a directory, not a file - #{value}"
      end
    end

    def check_if_option_file_exists_and_readable(name)
      check_if_option_exists(name)

      value = instance_variable_get("@#{name}")

      unless File.file?(value)
        raise CommandLineError, "[--#{argument_name(name)}] File doesn't exists - #{value}"
      end

      unless File.readable?(value)
        raise CommandLineError, "[--#{argument_name(name)}] File isn't readable - #{value}"
      end
    end

    def check_option_version_files_directory(name)
      check_if_option_directory_exists(name)

      value = instance_variable_get("@#{name}")

      if FileHelper.only_zip_file_in_directory(value)
        raise CommandLineError, "[--#{argument_name(name)}] You've selected a directory that "\
        "contains a single zip file #{value}. You need to pass a directory with unzipped files of "\
        "your application."
      end
    end

    protected

      def raise_error(message)
        raise CommandLineError, message
      end

    private

      def argument_name(name)
        name.to_s.tr('_', '-')
      end
  end
end
