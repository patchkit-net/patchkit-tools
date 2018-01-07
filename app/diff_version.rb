#!/usr/bin/env ruby

=begin
$META_START$
name: diff-version
summary: Creates version diff file from signatures.
basic: false
class: PatchKitTools::DiffVersionTool
$META_END$
=end

require_relative 'core/patchkit_api.rb'
require_relative 'core/patchkit_tools.rb'
require_relative 'core/patchkit_version_diff.rb'

module PatchKitTools
  class DiffVersionTool < PatchKitTools::BaseTool
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
      check_option_version_files_directory("files")
      check_if_option_exists("diff")
      check_if_option_exists("diff_summary")

      Dir.mktmpdir do |temp_dir|
        temporary_signatures_directory = "#{temp_dir}/signatures"
        temporary_diff_directory = "#{temp_dir}/diff"

        puts "Unpacking signatures..."

        ZipHelper.unzip(self.signatures, temporary_signatures_directory)

        puts "Creating diff..."

        diff_summary = PatchKitVersionDiff.create_diff(
          self.files, temporary_signatures_directory, temporary_diff_directory, self.diff
        )

        puts "Saving diff summary..."

        diff_summary_file = File.open(self.diff_summary, 'wb')
        begin
          diff_summary_file.write diff_summary
        ensure
          diff_summary_file.close
        end
      end
    end
  end
end

if $0 == __FILE__
  PatchKitTools::execute_tool PatchKitTools::DiffVersionTool.new
end
