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
require_relative 'core/base_tool2.rb'
require_relative 'core/utils/s3_uploader'
require_relative 'core/utils/speed_calculator'
require_relative 'core/model/app'
require_relative 'core/patchkit_config'

require 'rubygems'
require 'bundler/setup'
require 'net/http/uploadprogress'
require 'digest'

include PatchKitTools::Model

module PatchKitTools
  class UploadVersionTool < PatchKitTools::BaseTool2
    UPLOAD_MODES = ["content", "diff"]

    # after successful upload, you can read the result job GUID here
    attr_reader :processing_job_guid

    attr_writer :secret,
                :api_key,
                :version,
                :mode,
                :file,
                :diff_summary,
                :wait_for_job


    def initialize(argv = ARGV)
      super(argv, "upload-version", "Uploads new version by sending content or diff.",
            "-m content -s <secret> -a <api_key> -v <version> -f <file> [optional]",
            "-m diff -s <secret> -a <api_key> -v <version> -f <file> -d <diff_summary> [optional]")

      @wait_for_job = true
      @secret = nil
      @api_key = nil
      @version = nil
      @mode = nil
      @file = nil
      @diff_summary = nil
      @retry_count = PatchKitConfig.upload_retry_count
      @ask_to_try_again = PatchKitConfig.upload_ask_to_try_again
    end

    def parse_options
      super do |opts|
        opts.separator "Mandatory"

        opts.on("-s", "--secret <secret>",
          "application secret") do |secret|
          @secret = secret
        end

        opts.on("-a", "--api-key <api_key>",
          "user API key") do |api_key|
          @api_key = api_key
        end

        opts.on("-v", "--version <version>", Integer,
          "application version") do |version|
          @version = version
        end

        opts.on("-m", "--mode <mode>",
          "upload mode; #{UPLOAD_MODES.join(", ")}") do |mode|
          @mode = mode
        end

        opts.on("-f", "--file <file>",
          "file to upload") do |file|
          @file = file
        end

        opts.on("-d", "--diff-summary-file <diff_summary>",
          "file with diff summary (required only when --mode=diff)") do |diff_summary|
            @diff_summary = diff_summary
        end

        opts.separator ""

        opts.separator "Optional"

        opts.on("-w", "--wait-for-job <true | false>",
          "should program wait for finish of version processing job (default: #{@wait_for_job})") do |wait_for_job|
            @wait_for_job = wait_for_job
        end

        opts.on("-r", "--retry <count>", "Number of retries (default: #{@retry_count})") do |val|
          @retry_count = val.to_i
        end

        opts.on("--ask-to-try-again <true | false>",
                "Ask to try again if all attempts have failed (default: #{@ask_to_try_again})") do |val|
          @ask_to_try_again = val == "true"
        end
      end
    end

    def execute
      check_if_option_exists("secret")
      check_if_option_exists("api_key")
      check_if_option_exists("version")
      check_if_valid_option_value("mode", UPLOAD_MODES)
      check_if_option_file_exists_and_readable("file")
      check_if_option_file_exists_and_readable("diff_summary") if @mode == "diff"

      # Check if the version is draft
      puts "Checking version..."
      app = App.find_by_secret!(@secret)
      
      version = Version.find_by_id!(app, @version)
      raise "Version must be a draft" unless version.draft?

      puts "Uploading #{@mode}..."

      file_size = File.size(@file)
      progress_bar = ProgressBar.new(file_size)

      speed_calculator = SpeedCalculator.new

      uploader = S3Uploader.new(@api_key)
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

      loop do
        begin
          3.times { puts }
          uploader.upload_file(@file)
          break
        rescue => e
          puts
          puts "Error during file upload: #{e}"
          @retry_count -= 1
          if @retry_count < 0
            if @ask_to_try_again
              if ask_yes_or_no("Try again?", 'y')
                next
              else
                raise CommandLineError, "Couldn't upload the file"
              end
            else
              raise CommandLineError, "Couldn't upload the file"
            end
          end
        end
      end
      upload_id = uploader.upload_id

      progress_bar.print(file_size, "Upload done", force: true)

      result = case @mode
               when 'content'
                 version.upload_content!(upload_id: upload_id)
               when 'diff'
                 version.upload_diff!(upload_id: upload_id,
                                      diff_summary: File.read(@diff_summary))
               else
                 raise "unknown mode: #{@mode}"
               end

      @processing_job_guid = result[:job_guid]
      # Optionally wait for finish of version processing job
      if @wait_for_job
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
