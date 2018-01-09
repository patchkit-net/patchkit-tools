# Base class for every tool

module PatchKitTools
  class BaseTool
    attr_reader :host

    def initialize(program_name, program_description, *program_usages)
      @source = OpenStruct.new
      @program_name = program_name
      @program_description = program_description
      @program_usages = program_usages

      @opts_defined = []
      @opts_used = []
      @opts_required = []
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

      yield @opt_parser

      @opt_parser.separator ""

      @opt_parser.separator "Common"

      unless @opts_defined.include? :host
        option('host', value: true, required: false, description: 'Hostname (format: patchkit.net)')
      end

      @opt_parser.on("-h", "--help", "outputs a usage message and exit") do
        puts @opt_parser
        exit
      end

      @opt_parser.separator ""

      @opt_parser.parse!(ARGV)

      @opts_required.each do |opt|
        raise CommandLineError, "Missing required option --#{opt}" unless @opts_used.include? opt
      end
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
      if eval(name).nil?
        result = ask("Please enter --#{get_argument_name(name)}")
        eval("self.#{name} = \"#{result}\"")
      end

      check_if_option_exists(name)
    end

    # Deprecated
    def check_if_option_exists(name)
      raise CommandLineError, "[--#{get_argument_name(name)}] Missing argument" if eval(name).nil? || (eval(name).is_a?(String) && eval(name).empty?)
    end

    def check_if_valid_option_value(name, possible_values)
      raise CommandLineError, "[--#{get_argument_name(name)}] Invalid argument value" unless possible_values.include? eval(name)
    end

    def check_if_option_directory_exists(name)
      check_if_option_exists(name)
      raise CommandLineError, "[--#{get_argument_name(name)}] Directory doesn't exists - #{eval(name)}" unless File.exists?(eval(name))
      raise CommandLineError, "[--#{get_argument_name(name)}] Excepted argument to be a directory, not a file - #{eval(name)}" unless File.directory?(eval(name))
    end

    def check_if_option_file_exists_and_readable(name)
      check_if_option_exists(name)
      raise CommandLineError, "[--#{get_argument_name(name)}] File doesn't exists - #{eval(name)}" unless File.file?(eval(name))
      raise CommandLineError, "[--#{get_argument_name(name)}] File isn't readable - #{eval(name)}" unless File.readable?(eval(name))
    end

    def check_option_version_files_directory(name)
      check_if_option_directory_exists(name)
      raise CommandLineError, "[--#{get_argument_name(name)}] You've selected a directory that contains a single zip file #{eval(name)}. You need to pass a directory with unzipped files of your application." if FileHelper::only_zip_file_in_directory(eval(name))
    end

    # Alias to @source
    def method_missing(method, *args, &block)
      @source.send(method, *args, &block)
    end

    def option(name, **opts)
      required = opts[:required]
      raise('need to specify :required option') if required.nil?

      letter = opts[:letter]
      description = opts[:description]
      with_value = opts[:value] || false

      if letter.nil?
        @opt_parser.on(
            "--#{name}" + (with_value ? " <#{name}>" : ""),
            description
        ) do |value|
          @opts_used << name.to_sym
          instance_variable_set("@#{name}", value) if with_value
        end
      else
        @opt_parser.on(
            "-#{letter}",
            "--#{name}" + (with_value ? " <#{name}>" : ""),
            description
        ) do |value|
          @opts_used << name.to_sym
          instance_variable_set("@#{name}", value) if with_value
        end
      end

      @opts_required << name.to_sym if required
      @opts_defined << name.to_sym
    end

    private

    def get_argument_name(name)
      name.delete('_')
    end
  end
end