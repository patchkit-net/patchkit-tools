require 'yaml'
require 'ostruct'

module PatchKitConfig
  private

  def self.get_config_path
    "#{File.dirname(__FILE__)}/../../config/config.yml"
  end

  public

  @config = OpenStruct.new YAML.load(File.open(self.get_config_path, 'rb') { |f| f.read })

  def self.method_missing(method, *args, &block)
    @config.send(method, *args, &block)
  end
end
