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

require 'rubygems'
require 'bundler/setup'
require 'net/http/uploadprogress'
require 'digest'

module PatchKitTools
  # after successful upload, you can read the result job GUID here
  attr_reader :processing_job_guid

  class UploadVersionTool < PatchKitTools::BaseTool
    UPLOAD_MODES = ["content", "diff"]

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
      version_status = (PatchKitAPI::ResourceRequest.new "1/apps/#{self.secret}/versions/#{self.version}?api_key=#{self.api_key}").get_object
      raise "Version must be a draft" unless version_status["draft"]

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

      update_version_resource_name, update_version_resource_form = case self.mode
      when "content"
        [
          "1/apps/#{self.secret}/versions/#{self.version}/content_file?api_key=#{self.api_key}",
          {
            "upload_id" => upload_id.to_s
          }
        ]
      when "diff"
        [
          "1/apps/#{self.secret}/versions/#{self.version}/diff_file?api_key=#{self.api_key}",
          {
            "upload_id" => upload_id.to_s,
            "diff_summary" => File.open(self.diff_summary, 'rb') { |f| f.read }
          }
        ]
      end

      update_version_resource_request = PatchKitAPI::ResourceRequest.new(update_version_resource_name, Net::HTTP::Put)
      update_version_resource_request.form = update_version_resource_form

      update_version_resource_request.get_object do |object|
        @processing_job_guid = object['job_guid']
        # Optionally wait for finish of version processing job
        if self.wait_for_job
          puts "Waiting for finish of version processing job..."

          # Display job progress bar
          PatchKitAPI.display_job_progress(@processing_job_guid)
        end
      end
    end
  end
end

if $0 == __FILE__
  PatchKitTools::execute_tool PatchKitTools::UploadVersionTool.new
end
