#!/usr/bin/env ruby

require_relative 'api.rb'
require 'optparse'
require 'ostruct'

args = ARGV
args = $passed_args if __FILE__ != $0

options = OpenStruct.new

opt_parser = OptionParser.new do |opts|
  opts.banner = "Usage: patchkit-tools app-versions-signature [options]"

  opts.separator ""

  opts.separator "Specific options:"

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

  opts.separator ""
  opts.separator "Common options:"

  opts.on_tail("-h", "--help", "show this message") do
    puts opts
    exit
  end
end

opt_parser.parse!(args)

if options.secret.nil?
  puts "ERROR: Missing argument value --secret SECRET"
  puts ""
  puts opt_parser.help
  exit
end

if options.api_key.nil?
  puts "ERROR: Missing argument value --apikey API_KEY"
  puts ""
  puts opt_parser.help
  exit
end

if options.output.nil?
  puts "ERROR: Missing argument value --output OUTPUT_FILE"
  puts ""
  puts opt_parser.help
  exit
end

latest_version = PatchKitAPI::ResourceRequest.new("1/apps/#{options.secret}/versions/latest").get_object["id"]

PatchKitAPI::ResourceRequest.new("1/apps/#{options.secret}/versions/#{latest_version}/signatures?api_key=#{options.api_key}").get_response do |response|
  File.open(options.output, 'w') do |file|
    progress_bar = ProgressBar.new(response.content_length)
    total_length = 0.0
    response.read_body do |segment|
      file.write segment
      total_length += segment.length
      progress_bar.print(total_length, "Downloading signature - #{(total_length / 1024.0 / 1024.0).round(2)} MB out of #{(response.content_length / 1024.0 / 1024.0).round(2)} MB")
    end
    progress_bar.print(response.content_length, "Done!")
  end
end
