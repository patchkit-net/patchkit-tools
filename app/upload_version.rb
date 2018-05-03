#!/usr/bin/env ruby

=begin
$META_START$
name: upload-version
summary: Uploads new version by sending content or diff file.
basic: false
class: PatchKitTools::UploadVersionTool
$META_END$
=end

require_relative 'core/patchkit_api.rb'
require_relative 'core/patchkit_tools.rb'
require_relative 'core/utils/s3_uploader'
require_relative 'core/utils/speed_calculator'
require_relative 'core/model/app'

require 'rubygems'
require 'bundler/setup'
require 'net/http/uploadprogress'
require 'digest'

module PatchKitTools
  class UploadVersionTool < PatchKitTools::BaseTool
    UPLOAD_MODES = ["content", "diff"]

    # after successful upload, you can read the result job GUID here
    attr_reader :processing_job_guid

    def initialize
      super("upload-version", "Uploads new version by sending content or diff.",
            "-m content -s <secret> -a <api_key> -v <version> -f <file> [optional]",
            "-m diff -s <secret> -a <api_key> -v <version> -f <file> -d <diff_summary> [optional]")

      self.wait_for_job = true
    end

    def parse_options
      super do |opts|
        opts.separator "Mandatory"

        opts.on("-s", "--secret <secret>",
          "application secret") do |secret|
          self.secret = secret
        end

        opts.on("-a", "--apikey <api_key>",
          "user API key") do |api_key|
          self.api_key = api_key
        end

        opts.on("-v", "--version <version>", Integer,
          "application version") do |version|
          self.version = version
        end

        opts.on("-m", "--mode <mode>",
          "upload mode; #{UPLOAD_MODES.join(", ")}") do |mode|
          self.mode = mode
        end

        opts.on("-f", "--file <file>",
          "file to upload") do |file|
          self.file = file
        end

        opts.on("-d", "--diffsummary <diff_summary>",
          "file with diff summary (required only when --mode=diff)") do |diff_summary|
            self.diff_summary = diff_summary
        end

        opts.separator ""

        opts.separator "Optional"

        opts.on("-w", "--waitforjob <true | false>",
          "should program wait for finish of version processing job (default: #{self.wait_for_job})") do |wait_for_job|
            self.wait_for_job = wait_for_job
          end
      end
    end

    def execute
      check_if_option_exists("secret")
      check_if_option_exists("api_key")
      check_if_option_exists("version")
      check_if_valid_option_value("mode", UPLOAD_MODES)
      check_if_option_file_exists_and_readable("file")
      check_if_option_file_exists_and_readable("diff_summary") if self.mode == "diff"

      # Check if the version is draft
      puts "Checking version..."
      app = App.find_by_secret!(self.secret)
      
      version = Version.find_by_id!(app, self.version)
      raise "Version must be a draft" unless version.draft?

      puts "Uploading #{self.mode}..."

      file_size = File.size(self.file)
      progress_bar = ProgressBar.new(file_size)

      speed_calculator = SpeedCalculator.new

      uploader = S3Uploader.new(api_key)
      uploader.on(:progress) do |bytes_sent, bytes_total|
        speed_calculator.submit(bytes_sent)

        text = if speed_calculator.ready?
                 format("Uploading %.2f MB out of %.2f MB (%.2f MB/s)",
                        bytes_sent / 1024.0**2,
                        bytes_total / 1024.0**2,
                        speed_calculator.speed_per_second / 1024.0**2)
               else
                 format("Uploading %.2f MB out of %.2f MB",
                        bytes_sent / 1024.0**2,
                        bytes_total / 1024.0**2)
               end

        progress_bar.print(bytes_sent, text)
      end

      uploader.upload_file(file)
      upload_id = uploader.upload_id

      progress_bar.print(file_size, "Upload done")

      result = case self.mode
               when 'content'
                 version.upload_content!(upload_id: upload_id)
               when 'diff'
                 version.upload_diff!(upload_id: upload_id,
                                      diff_summary: File.read(self.diff_summary))
               else
                 raise "unknown mode: #{self.mode}"
               end

      @processing_job_guid = result[:job_guid]
      # Optionally wait for finish of version processing job
      if self.wait_for_job
        puts "Waiting for finish of version processing job..."

        # Display job progress bar
        PatchKitAPI.display_job_progress(@processing_job_guid)
      end
    end
  end
end

if $0 == __FILE__
  PatchKitTools::execute_tool PatchKitTools::UploadVersionTool.new
end
