#!/usr/bin/env ruby

=begin
$META_START$
name: diff-version
summary: Creates version diff file from signatures.
basic: false
class: PatchKitTools::DiffVersionTool
$META_END$
=end

require 'base64'

require_relative 'core/patchkit_api.rb'
require_relative 'core/patchkit_tools.rb'
require_relative 'core/patchkit_version_diff.rb'
require_relative 'core/utils/windows_long_path.rb'

module PatchKitTools
  class DiffVersionTool < PatchKitTools::BaseTool
    attr_reader :sha1

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

        opts.on("--algorithm <algorithm>",
                "algorithm used to create diff (default: zip, options: zip, pack1)") do |algorithm|
          self.algorithm = algorithm.to_sym
        end

        opts.on("--delta-algorithm <algorithm>",
                "algorithm used to create diff (default: librsync, options: librsync, turbopatch)") do |algorithm|
          self.delta_algorithm = algorithm.to_sym
        end

        opts.on("--pack1-key <pack1_key>",
                "base64 encoded key used to create pack1 diff") do |pack1_key|
          self.pack1_key = pack1_key
        end

        opts.on("-m", "--diff-summary <diff_summary>",
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

      self.algorithm = :zip if self.algorithm.nil?
      self.delta_algorithm = :librsync if self.delta_algorithm.nil?

      temp_dir = Dir.mktmpdir
      begin
        temporary_signatures_directory = "#{temp_dir}/signatures"
        temporary_diff_directory = "#{temp_dir}/diff"

        puts "Unpacking signatures..."

        ZipHelper.unzip(self.signatures, temporary_signatures_directory, add_underscores_to_files: true)

        puts "Creating diff..."

        output_file = self.diff
        if self.algorithm.to_sym == :pack1
          output_file = [self.diff, "#{self.diff}.meta"]
        end

        pack1_key = Base64.decode64(self.pack1_key) unless self.pack1_key.nil?

        create_diff_result =
          PatchKitVersionDiff.create_diff(self.files, temporary_signatures_directory, temporary_diff_directory,
                                          output_file,
                                          packaging_algorithm: self.algorithm,
                                          delta_algorithm: self.delta_algorithm,
                                          pack1_key: pack1_key,
                                          previous_files_hashes: self.previous_files_hashes,
                                          signatures_are_underscored: true)
        diff_summary = create_diff_result.diff_summary
        @sha1 = create_diff_result.sha1

        puts "SHA1 of the diff file: #{@sha1}"

        puts
        puts "Saving diff summary..."

        diff_summary_file = File.open(WindowsLongPath.fix(self.diff_summary), 'wb')
        begin
          diff_summary_file.write diff_summary
        ensure
          diff_summary_file.close
        end
      ensure
        WindowsLongPath.safe_rm_rf(temp_dir)
      end
    end
  end
end

if $0 == __FILE__
  PatchKitTools::execute_tool PatchKitTools::DiffVersionTool.new
end
