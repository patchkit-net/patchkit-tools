#!/usr/bin/env ruby

=begin
$META_START$
name: content-version
summary: Creates version content file.
basic: false
class: PatchKitTools::ContentVersionTool
$META_END$
=end

require_relative 'core/patchkit_api.rb'
require_relative 'core/patchkit_tools.rb'
require_relative 'core/patchkit_version_content.rb'

module PatchKitTools
  class ContentVersionTool < PatchKitTools::BaseTool
    def initialize
      super("content-version", "Creates version content from new version files.",
            "-f <files> -c <content>")
    end

    def parse_options
      super do |opts|
        opts.separator "Mandatory"

        opts.on("-f", "--files <files>",
          "directory with new version files") do |files|
          self.files = files
        end

        opts.on("-c", "--content <content>",
          "output content file") do |diff|
          self.diff = diff
        end
      end
    end

    def execute
      check_option_version_files_directory("files")

      puts "Creating content..."

      PatchKitVersionContent::create_content(self.files, self.content)
    end
  end
end

if $0 == __FILE__
  PatchKitTools::execute_tool PatchKitTools::ContentVersionTool.new
end
