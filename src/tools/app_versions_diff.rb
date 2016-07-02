#!/usr/bin/env ruby

require_relative 'api.rb'
require 'optparse'
require 'ostruct'

args = ARGV
args = $passed_args if __FILE__ != $0

options = OpenStruct.new

opt_parser = OptionParser.new do |opts|
	opts.banner = "Usage: patchkit-tools app-versions-diff [options]"

	opts.separator ""

	opts.separator "Specific options:"

	opts.on("-s", "--signature SIGNATURE_FILE",
		"file with previous version signatures",
		"read more - type 'patchkit-tools app-versions-signature --help'") do |signature|
		options.signature = signature
	end

	opts.on("-f", "--files FILES_DIRECTORY",
		"directory with the newest version files") do |files|
		options.files = files
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

if options.signature.nil?
	puts "ERROR: Missing argument value --signature SIGNATURE_FILE"
	puts ""
	puts opt_parser.help
	exit
end

if options.files.nil?
	puts "ERROR: Missing argument value --files FILES_DIRECTORY"
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
