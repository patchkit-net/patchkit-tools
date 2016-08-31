#!/usr/bin/env ruby

require_relative 'lib/patchkit_api.rb'
require_relative 'lib/patchkit_tools.rb'
require 'net/http/uploadprogress'

UPLOAD_MODES = ["content", "diff"]

options = PatchKitTools::Options.new("upload-version", "Uploads new version by sending content or diff.",
                                     " -m content -s <secret> -a <api_key> -v <version> -f <file> [optional]",
                                     " -m diff -s <secret> -a <api_key> -v <version> -f <file> -d <diff_summary>  [optional]")
options.wait_for_job = true

options.parse(__FILE__ != $0 ? $passed_args : ARGV) do |opts|
  opts.separator "Mandatory"

  opts.on("-s", "--secret <secret>",
    "application secret") do |secret|
    options.secret = secret
  end

  opts.on("-a", "--apikey <api_key>",
    "user API key") do |api_key|
    options.api_key = api_key
  end

  opts.on("-v", "--version <version>", Integer,
    "application version") do |version|
    options.version = version
  end

  opts.on("-m", "--mode <mode>",
    "upload mode; #{UPLOAD_MODES.join(", ")}") do |mode|
    options.mode = mode
  end

  opts.on("-f", "--file <file>",
    "file to upload") do |file|
    options.file = file
  end

  opts.on("-d", "--diffsummary <diff_summary>",
    "file with diff summary (required only when --mode diff)") do |diff_summary|
      options.diff_summary = diff_summary
  end

  opts.separator ""

  opts.separator "Optional"

  opts.on("-w", "--waitforjob <true | false>",
    "should program wait for finish of version processing job (default: #{options.wait_for_job})") do |wait_for_job|
      options.wait_for_job = wait_for_job
    end
end

options.error_argument_missing("secret") if options.secret.nil?
options.error_argument_missing("apikey") if options.api_key.nil?
options.error_argument_missing("version") if options.version.nil?
options.error_argument_missing("mode") if options.mode.nil?
options.error_invalid_argument_value("mode") unless UPLOAD_MODES.include? options.mode
options.error_argument_missing("file") if options.file.nil?
options.error_argument_missing("diffsummary") if options.mode == "diff" && options.diff_summary.nil?

# Check if the version is draft
puts "Checking version..."
version_status = (PatchKitAPI::ResourceRequest.new "1/apps/#{options.secret}/versions/#{options.version}?api_key=#{options.api_key}").get_object
raise "Version must be a draft" unless version_status["draft"]

File.open(options.file) do |file|
  # Depending on the current mode, choose resource name and form data
  resource_name, resource_form = case options.mode
  when "content"
      [
        "1/apps/#{options.secret}/versions/#{options.version}/content_file?api_key=#{options.api_key}",
        {
          "file" => file
        }
      ]
    when "diff"
      [
        "1/apps/#{options.secret}/versions/#{options.version}/diff_file?api_key=#{options.api_key}",
        {
          "file" => file,
          "diff_summary" => File.open(options.diff_summary, 'rb') { |f| f.read }
        }
      ]
  end

  puts "Uploading #{options.mode}..."

  # Create upload request
  resource_request = PatchKitAPI::ResourceRequest.new(resource_name, resource_form, Net::HTTP::Put)

  # Initialize progress bar
  progress_bar = ProgressBar.new(file.size)
  Net::HTTP::UploadProgress.new(resource_request.http_request) do |progress|
    progress_bar.print(progress.upload_size, "Uploading #{(progress.upload_size / 1024.0 / 1024.0).round(2)} MB out of #{(file.size / 1024.0 / 1024.0).round(2)} MB")
  end

  resource_request.get_object do |object|
    # Optionally wait for finish of version processing job
    if(options.wait_for_job)
      puts "Waiting for finish of version processing job..."

      # Display job progress bar
      PatchKitAPI.display_job_progress(object["job_guid"])
    end
  end

  puts "Done!"
end
