#!/usr/bin/env ruby

require_relative 'api.rb'
require 'ruby-progressbar'
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

latest_version = PatchKitAPI.get_resource_object("1/apps/#{options.secret}/versions/latest")["id"]

PatchKitAPI.get_resource_response("1/apps/#{options.secret}/versions/#{latest_version}/signatures?api_key=#{options.api_key}") do |response|
  File.open(options.output, 'w') do |file|
    progressBar = ProgressBar.create

    progressBar.total = response.content_length

    response.read_body do |segment|
      file.write segment
      progressBar.progress += segment.length
    end

    puts ""
  end
end
