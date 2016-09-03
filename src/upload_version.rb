#!/usr/bin/env ruby

require_relative 'lib/patchkit_api.rb'
require_relative 'lib/patchkit_tools.rb'

module PatchKitTools
  class UploadVersionTool < PatchKitTools::Tool
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
      check_if_option_file_exists("file")
      check_if_option_file_exists("diff_summary") if self.mode == "diff"

      # Check if the version is draft
      puts "Checking version..."
      version_status = (PatchKitAPI::ResourceRequest.new "1/apps/#{self.secret}/versions/#{self.version}?api_key=#{self.api_key}").get_object
      raise "Version must be a draft" unless version_status["draft"]

      File.open(self.file) do |file|
        # Depending on the current mode, choose resource name and form data
        resource_name, resource_form = case self.mode
        when "content"
            [
              "1/apps/#{self.secret}/versions/#{self.version}/content_file?api_key=#{self.api_key}",
              {
                "file" => file
              }
            ]
          when "diff"
            [
              "1/apps/#{self.secret}/versions/#{self.version}/diff_file?api_key=#{self.api_key}",
              {
                "file" => file,
                "diff_summary" => File.open(self.diff_summary, 'rb') { |f| f.read }
              }
            ]
        end

        puts "Uploading #{self.mode}..."

        # Create upload request
        resource_request = PatchKitAPI::ResourceRequest.new(resource_name, resource_form, Net::HTTP::Put)

        # Initialize progress bar
        progress_bar = ProgressBar.new(file.size)
        Net::HTTP::UploadProgress.new(resource_request.http_request) do |progress|
          progress_bar.print(progress.upload_size, "Uploading #{(progress.upload_size / 1024.0 / 1024.0).round(2)} MB out of #{(file.size / 1024.0 / 1024.0).round(2)} MB")
        end

        resource_request.get_object do |object|
          # Optionally wait for finish of version processing job
          if(self.wait_for_job)
            puts "Waiting for finish of version processing job..."

            # Display job progress bar
            PatchKitAPI.display_job_progress(object["job_guid"])
          end
        end

        puts "Done!"
      end
    end
  end
end

if $0 == __FILE__
  PatchKitTools::execute_tool PatchKitTools::UploadVersionTool.new
end
