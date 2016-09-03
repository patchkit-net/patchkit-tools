#!/usr/bin/env ruby

require_relative 'lib/patchkit_api.rb'
require_relative 'lib/patchkit_tools.rb'
require_relative 'lib/diff_helper.rb'

module PatchKitTools
  class DiffVersionTool < PatchKitTools::Tool
    TEMPORARY_DIRECTORY = "diff_temporary"

    def initialize
      super("diff-version", "Creates version diff from previous version signatures zip and new version files.",
            "-s <signatures> -f <files> -d <diff> -m <diff_summary>")
    end

    def parse_options
      super do |opts|
        opts.separator "Mandatory"

        opts.on("-s", "--signatures <signatures>",
          "zip with previous version signatures",
          "learn how to get signatures - type 'patchkit-tools download-version-signatures --help'") do |signatures|
          self.signatures = signatures
        end

        opts.on("-f", "--files <files>",
          "directory with new version files") do |files|
          self.files = files
        end

        opts.on("-d", "--diff <diff>",
          "output diff file") do |diff|
          self.diff = diff
        end

        opts.on("-m", "--diffsummary <diff_summary>",
          "output diff summary file") do |diff_summary|
          self.diff_summary = diff_summary
        end
      end
    end

    def execute
      check_if_option_exists("signatures")
      check_if_option_directory_exists("files")
      check_if_option_exists("diff")
      check_if_option_exists("diff_summary")

      begin
        temporary_signatures_directory = "#{TEMPORARY_DIRECTORY}/signatures"
        temporary_diff_directory = "#{TEMPORARY_DIRECTORY}/diff"

        puts "Unpacking signatures..."

        ZipHelper.unzip(options.signatures, temporary_signatures_directory)

        puts "Creating diff..."

        diff_summary = DiffHelper::create_diff(options.files, temporary_signatures_directory, temporary_diff_directory, options.diff)

        puts "Saving diff summary..."

        diff_summary_file = File.open(options.diff_summary, 'wb')
        begin
          diff_summary_file.write diff_summary
        ensure
          diff_summary_file.close
        end

        puts "Done!"
      ensure
        # Delete temporary directory
        FileUtils.rm_rf temporary_directory
      end
    end
  end
end

if $0 == __FILE__
  PatchKitTools::execute_tool PatchKitTools::DiffVersionTool.new
end
