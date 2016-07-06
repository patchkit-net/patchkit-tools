#!/usr/bin/env ruby

require_relative 'lib/patchkit_api.rb'
require_relative 'lib/patchkit_tools.rb'

options = PatchKitTools::Options.new("download-version-signatures", "Downloads version signatures package")

options.parse(__FILE__ != $0 ? $passed_args : ARGV) do |opts|
  opts.on("-s", "--secret SECRET",
    "application secret") do |secret|
    options.secret = secret
  end

  opts.on("-a", "--apikey API_KEY",
    "user API key") do |api_key|
    options.api_key = api_key
  end

  opts.on("-v", "--version VERSION", Integer,
    "application version") do |version|
    options.version = version
  end

  opts.on("-o", "--output OUTPUT",
    "output file") do |output|
    options.output = output
  end
end

options.error_argument_missing("secret") if options.secret.nil?
options.error_argument_missing("apikey") if options.api_key.nil?
options.error_argument_missing("version") if options.version.nil?
options.error_argument_missing("output") if options.output.nil?

# Download version signatures
PatchKitAPI::ResourceRequest.new("1/apps/#{options.secret}/versions/#{options.version}/signatures?api_key=#{options.api_key}").get_response do |response|
  # Create output file
  file = File.open(options.output, 'wb')
  begin
    # Create progress bar
    progress_bar = ProgressBar.new(response.content_length)
    total_length = 0.0
    response.read_body do |segment|
      # Write segment to file
      file.write segment

      # Upadate progres bar
      total_length += segment.length
      progress_bar.print(total_length, "Downloading signature - #{(total_length / 1024.0 / 1024.0).round(2)} MB out of #{(response.content_length / 1024.0 / 1024.0).round(2)} MB")
    end
    progress_bar.print(response.content_length, "Done!")
  ensure
    file.close
  end
end
