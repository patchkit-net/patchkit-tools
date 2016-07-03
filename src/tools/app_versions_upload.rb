#!/usr/bin/env ruby

require_relative 'lib/patchkit_api.rb'
require_relative 'lib/patchkit_tools.rb'

UPLOAD_TYPES = ["content", "diff"]

options = PatchKitTools::Options.new

options.parse("app-versions-upload", __FILE__ != $0 ? $passed_args : ARGV) do |opts|
  opts.on("-s", "--secret SECRET",
    "application secret") do |secret|
    options.secret = secret
  end

  opts.on("-a", "--apikey API_KEY",
    "user API key") do |api_key|
    options.api_key = api_key
  end

  opts.on("-t", "--type TYPE",
    "upload type; #{UPLOAD_TYPES.join(", ")}") do |type|
    options.type = type
  end

  opts.on("-f", "--file FILE",
    "file to upload") do |file|
    options.file = file
  end

  opts.on("-c", "--changelog [CHANGELOG]",
    "version changelog") do |changelog|
    options.changelog = changelog
  end

  opts.on("-d", "-diffsummary [DIFF_SUMMARY]",
    "diff summary (required when --type diff)") do |diff_summary|
      options.diff_summary = diff_summary
  end
end

options.error_argument_missing("secret") if options.secret.nil?
options.error_argument_missing("apikey") if options.api_key.nil?
options.error_argument_missing("type") if options.type.nil?
options.error_invalid_argument_value("type") if !UPLOAD_TYPES.include? options.type
options.error_argument_missing("diffsummary") if options.type == "diff" && options.diff_summary.nil?
options.error_argument_missing("file") if options.file.nil?

latest_version = (PatchKitAPI::ResourceRequest.new "1/apps/#{options.secret}/versions").get_object.detect {|version| version["draft"] == true}["id"]

File.open(options.file) do |file|
  resource_name, resource_form = case options.type
  when "content"
      [
        "1/apps/#{options.secret}/versions/#{latest_version}/content_file?api_key=#{options.api_key}",
        {
          "file" => file
        }
      ]
    when "content"
      [
        "1/apps/#{options.secret}/versions/#{latest_version}/diff_file?api_key=#{options.api_key}",
        {
          "file" => file,
          "diff_summary" => options.diff_summary
        }
      ]
  end

  resource_request = PatchKitAPI::ResourceRequest.new(resource_name, resource_form, Net::HTTP::Put)

  progress_bar = ProgressBar.new(file.size)
  Net::HTTP::UploadProgress.new(resource_request.http_request) do |progress|
    progress_bar.print(progress.upload_size, "Uploading #{(progress.upload_size / 1024.0 / 1024.0).round(2)} MB out of #{(file.size / 1024.0 / 1024.0).round(2)} MB")
  end

  resource_request.get_object do |object|
    progress_bar.print(file.size, "Done!")
    PatchKitAPI.display_job_progress(object["job_guid"])
  end
end
