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

	opts.on("-l", "--label LABEL",
		"version label") do |label|
		options.label = label
	end

	opts.on("-c", "--changelog [CHANGELOG]",
		"version changelog") do |changelog|
		options.changelog = changelog
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

if options.label.nil?
	puts "ERROR: Missing argument value --label LABEL"
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

resource_name = "/1/apps/#{options.secret}/versions"

resource_url = PatchKitAPI.get_resource_uri(resource_name)

File.open(options.file) do |file|
	response = Net::HTTP.start(resource_url.host, resource_url.port) do |http|
		request = Net::HTTP::Post.new resource_url.path
		request.set_form_data({"api_key" => options.api_key})
		request.set_form({
			"#{options.type}_file" => file,
			"label" => options.label
			}, "multipart/form-data")


		progressBar = ProgressBar.create

		Net::HTTP::UploadProgress.new(request) do |progress|
			progressBar.progress = [[(progress.upload_size.to_f / file.size) * 100.0,100].min, 0].max
		end

		http.request(request)
	end

	if response.kind_of?(Net::HTTPSuccess)
		puts response.body
	else
		raise "[#{response.code}] #{response.msg}"
	end
end
