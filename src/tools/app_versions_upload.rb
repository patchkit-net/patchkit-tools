#!/usr/bin/env ruby

require_relative 'api.rb'
require 'ruby-progressbar'
require 'optparse'
require 'ostruct'

args = ARGV
args = $passed_args if __FILE__ != $0

UPLOAD_TYPES = ["content", "diff"]

options = OpenStruct.new

opt_parser = OptionParser.new do |opts|
	opts.banner = "Usage: patchkit-tools app-versions-upload [options]"

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

if options.type.nil?
	puts "ERROR: Missing argument value --type TYPE"
	puts ""
	puts opt_parser.help
	exit
end

if !UPLOAD_TYPES.include? options.type
	puts "ERROR: Invaild argument value --type TYPE"
	puts ""
	puts opt_parser.help
	exit
end

if options.file.nil?
	puts "ERROR: Missing argument value --file FILE"
	puts ""
	puts opt_parser.help
	exit
end

if options.type == "diff" && options.diff_summary.nil?
  puts "ERROR: Missing argument value --diffsummary DIFF_SUMMARY"
	puts ""
	puts opt_parser.help
	exit
end

latest_version = PatchKitAPI.get_resource_object("1/apps/#{options.secret}/versions").detect {|version| version["draft"] == true}["id"]

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

  PatchKitAPI.get_resource_response(resource_name, resource_form, Net::HTTP::Put, lambda do |request|
    progressBar = ProgressBar.create

		Net::HTTP::UploadProgress.new(request) do |progress|
			progressBar.progress = [[(progress.upload_size.to_f / file.size) * 100.0,100].min, 0].max
		end
  end) do |response|
    puts response.body
  end
end
