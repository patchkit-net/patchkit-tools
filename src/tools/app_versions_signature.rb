#!/usr/bin/env ruby

require_relative 'lib/patchkit_api.rb'
require_relative 'lib/patchkit_tools.rb'

options = PatchKitTools::Options.new

options.parse("app-versions-signature", __FILE__ != $0 ? $passed_args : ARGV) do |opts|
  opts.on("-s", "--secret SECRET",
    "application secret") do |secret|
    options.secret = secret
  end

  opts.on("-a", "--apikey API_KEY",
    "user API key") do |api_key|
    options.api_key = api_key
  end

  opts.on("-o", "--output OUTPUT_FILE",
    "output file") do |output|
    options.output = output
  end
end

options.error_argument_missing("secret") if options.secret.nil?
options.error_argument_missing("apikey") if options.api_key.nil?
options.error_argument_missing("output") if options.output.nil?

latest_version = PatchKitAPI::ResourceRequest.new("1/apps/#{options.secret}/versions/latest").get_object["id"]

puts "1/apps/#{options.secret}/versions/#{latest_version}/signatures?api_key=#{options.api_key}"

PatchKitAPI::ResourceRequest.new("1/apps/#{options.secret}/versions/#{latest_version}/signatures?api_key=#{options.api_key}").get_response do |response|
  file = File.open(options.output, 'w')
  begin
    progress_bar = ProgressBar.new(response.content_length)
    total_length = 0.0
    response.read_body do |segment|
      file.write segment
      total_length += segment.length
      progress_bar.print(total_length, "Downloading signature - #{(total_length / 1024.0 / 1024.0).round(2)} MB out of #{(response.content_length / 1024.0 / 1024.0).round(2)} MB")
    end
    progress_bar.print(response.content_length, "Done!")
  ensure
    file.close
  end
end
