#!/usr/bin/env ruby

require_relative 'lib/patchkit_api.rb'
require_relative 'lib/patchkit_tools.rb'
require 'net/http/uploadprogress'

UPLOAD_MODES = ["content", "diff"]

tool = PatchKitTools::Tool.new("upload-version", "Uploads new version by sending content or diff.",
                                     "-m content -s <secret> -a <api_key> -v <version> -f <file> [optional]",
                                     "-m diff -s <secret> -a <api_key> -v <version> -f <file> -d <diff_summary> [optional]")
tool.wait_for_job = true

tool.parse_arguments do |opts|
  opts.separator "Mandatory"

  opts.on("-s", "--secret <secret>",
    "application secret") do |secret|
    tool.secret = secret
  end

  opts.on("-a", "--apikey <api_key>",
    "user API key") do |api_key|
    tool.api_key = api_key
  end

  opts.on("-v", "--version <version>", Integer,
    "application version") do |version|
    tool.version = version
  end

  opts.on("-m", "--mode <mode>",
    "upload mode; #{UPLOAD_MODES.join(", ")}") do |mode|
    tool.mode = mode
  end

  opts.on("-f", "--file <file>",
    "file to upload") do |file|
    tool.file = file
  end

  opts.on("-d", "--diffsummary <diff_summary>",
    "file with diff summary (required only when --mode diff)") do |diff_summary|
      tool.diff_summary = diff_summary
  end

  opts.separator ""

  opts.separator "Optional"

  opts.on("-w", "--waitforjob <true | false>",
    "should program wait for finish of version processing job (default: #{tool.wait_for_job})") do |wait_for_job|
      tool.wait_for_job = wait_for_job
    end
end

tool.check_if_argument_exists("secret")
tool.check_if_argument_exists("api_key")
tool.check_if_argument_exists("version")
tool.check_if_valid_argument_value("mode", UPLOAD_MODES)
tool.check_if_file_exists("file")
tool.check_if_file_exists("diff_summary") if tool.mode == "diff"

tool.execute do
  # Check if the version is draft
  puts "Checking version..."
  version_status = (PatchKitAPI::ResourceRequest.new "1/apps/#{tool.secret}/versions/#{tool.version}?api_key=#{tool.api_key}").get_object
  raise "Version must be a draft" unless version_status["draft"]

  File.open(tool.file) do |file|
    # Depending on the current mode, choose resource name and form data
    resource_name, resource_form = case tool.mode
    when "content"
        [
          "1/apps/#{tool.secret}/versions/#{tool.version}/content_file?api_key=#{tool.api_key}",
          {
            "file" => file
          }
        ]
      when "diff"
        [
          "1/apps/#{tool.secret}/versions/#{tool.version}/diff_file?api_key=#{tool.api_key}",
          {
            "file" => file,
            "diff_summary" => File.open(tool.diff_summary, 'rb') { |f| f.read }
          }
        ]
    end

    puts "Uploading #{tool.mode}..."

    # Create upload request
    resource_request = PatchKitAPI::ResourceRequest.new(resource_name, resource_form, Net::HTTP::Put)

    # Initialize progress bar
    progress_bar = ProgressBar.new(file.size)
    Net::HTTP::UploadProgress.new(resource_request.http_request) do |progress|
      progress_bar.print(progress.upload_size, "Uploading #{(progress.upload_size / 1024.0 / 1024.0).round(2)} MB out of #{(file.size / 1024.0 / 1024.0).round(2)} MB")
    end

    resource_request.get_object do |object|
      # Optionally wait for finish of version processing job
      if(tool.wait_for_job)
        puts "Waiting for finish of version processing job..."

        # Display job progress bar
        PatchKitAPI.display_job_progress(object["job_guid"])
      end
    end

    puts "Done!"
  end
end
