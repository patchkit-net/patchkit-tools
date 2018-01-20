require 'yaml'

module PatchKitTools
  # Tools manager
  class Tools
    def self.parse_all
      # it assumes that command files are one level up
      tools = parse_directory(File.join(File.dirname(__FILE__), '..'))

      internal_dir = ENV['PK_TOOLS_INTERNAL']
      tools.concat(parse_directory(internal_dir)) if !internal_dir.nil? && File.exist?(internal_dir)
      
      tools
    end

    def self.parse_directory(path, **opts)
      internal = opts[:internal] || false
      tools = []

      files = Dir["#{path}/*.rb"]
      files.each do |f|
        meta = read_meta_data(f)
        tool = parse_meta_data(meta, f)

        if !tool.nil?
          tool.internal = internal
          tools << tool
        else
          puts "Warning: File #{f} does not have valid tool meta data"
        end
      end

      tools
    end

    def self.read_meta_data(file)
      found = false
      meta = ""
      File.readlines(file).each do |line|
        line = line.strip
        case line
        when '$META_START$'
          found = true
        when '$META_END$'
          return meta
        else
          meta << "#{line}\n" if found
        end
      end
      meta
    end

    def self.parse_meta_data(meta, file)
      return nil if meta.nil? || meta.empty?

      yaml = YAML.load(meta)
      tool = ToolInfo.new
      tool.name = yaml['name']
      tool.summary = yaml['summary']
      tool.description = yaml['description']
      tool.basic = yaml['basic'].to_s == 'true'
      tool.cl = yaml['class'] || raise("Class not defined for #{file}")
      tool.file = file
      tool
    rescue
      puts "YAML:\n#{meta}"
      raise
    end
  end

  # Single command
  class ToolInfo
    attr_accessor :name
    attr_accessor :summary
    attr_accessor :description
    attr_accessor :basic
    alias basic? :basic
    attr_accessor :file
    attr_accessor :cl
    attr_accessor :internal
    alias internal? :basic

    def execute
      require @file
      PatchKitTools.execute_tool Kernel.const_get(@cl).new
    end
  end
end
