require 'yaml'
require 'ostruct'

##
# PatchKit Configuration
module PatchKitConfig
  class << self
    def config_path
      "#{File.dirname(__FILE__)}/../../config/config.local.yml"
    end

    def method_missing(method, *args, &block)
      if include? method
        value(method)
      else
        super
      end
    end

    def respond_to?(method, include_private = false)
      if include? method
        true
      else
        super
      end
    end

    def include?(key)
      [:debug, :api_url, :upload_chunk_size].include? key.to_sym
    end

    def value(key)
      if !@config.nil? && @config.respond_to?(key)
        @config.send(key)
      else
        send("default_#{key}")
      end
    end

    # default values

    def default_debug
      false
    end

    def default_api_url
      'http://api.patchkit.net'
    end

    def default_upload_chunk_size
      33_554_432 # 32 megabytes
    end
  end

  @config = OpenStruct.new YAML.load(File.open(config_path, 'r', &:read)) if File.exist? config_path
end
