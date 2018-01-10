require 'optparse'
require 'ostruct'
require_relative 'utils/file_helper.rb'
require_relative 'patchkit_error.rb'

module PatchKitTools
  def self.execute_tool(tool)
    begin
      tool.parse_options
      
      # override api_url if --host has been provided
      ::PatchKitAPI.api_url = "http://#{tool.host}/" if !tool.host.nil? && !tool.host.empty?

      tool.execute
      exit true
    rescue APIJobError, CommandLineError, OptionParser::MissingArgument => error
      puts "ERROR: #{error}"

      if PatchKitConfig.debug
        puts error.backtrace
        puts "Press return to continue..."
        STDIN.gets
      end

      exit false
    end
  end

  require_relative 'base_tool.rb'

end
