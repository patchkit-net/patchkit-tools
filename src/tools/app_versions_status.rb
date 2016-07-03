#!/usr/bin/env ruby

require_relative 'api.rb'
require 'optparse'
require 'ostruct'

DISPLAY_MODES = ["raw", "tree"]
DISPLAY_SORTS = ["desc", "asc"]

options = OpenStruct.new
options.display_mode = "tree"
options.display_limit = -1
options.display_sort = "desc"

opt_parser = OptionParser.new do |opts|
  opts.banner = "Usage: patchkit-tools app-versions-status [options]"

  opts.separator ""

  opts.separator "Specific options:"

  opts.on("-s", "--secret SECRET",
    "application secret") do |secret|
    options.secret = secret
  end

  opts.on("-a", "--apikey [API_KEY]",
    "user API key (displays draft version if supplied)") do |api_key|
    options.api_key = api_key
  end

  opts.on("-m", "--displaymode [DISPLAY_MODE]",
    "display mode; #{DISPLAY_MODES.join(", ")} (default: #{options.display_mode})") do |display_mode|
    options.display_mode = display_mode
  end

  opts.on("-l", "--displaylimit [LIMIT]", Integer,
    "limit of displayed versions; -1 = infinite (default: #{options.display_limit})") do |display_limit|
    options.display_limit = display_limit
  end

  opts.on("-b", "--displaysort [DISPLAY_SORT]",
    "display sort type; #{DISPLAY_SORTS.join(", ")} (default: #{options.display_sort})") do |display_sort|
    options.display_sort = display_sort
  end

  opts.separator ""
  opts.separator "Common options:"

  opts.on_tail("-h", "--help", "show this message") do
    puts opts
    exit
  end
end

opt_parser.parse!(ARGV)

if options.secret.nil?
  puts "ERROR: Missing argument value --secret SECRET"
  puts ""
  puts opt_parser.help
  exit
end

if !DISPLAY_MODES.include? options.display_mode
  puts "ERROR: Invaild argument value --displaymode [DISPLAY_MODE]"
  puts ""
  puts opt_parser.help
  exit
end

if !DISPLAY_SORTS.include? options.display_sort
  puts "ERROR: Invaild argument value --display_sort [DISPLAY_SORT]"
  puts ""
  puts opt_parser.help
  exit
end

status_resource_name = "1/apps/#{options.secret}/versions"
status_resource_name += "?api_key=#{options.api_key}" if not options.api_key.nil?

status = PatchKitAPI::ResourceRequest.new(status_resource_name).get_object

status = status.sort_by {|version| options.display_sort == "asc" ? version["id"] : -version["id"]}

if(options.display_limit > -1)
  status = status[0,[options.display_limit, status.length].min]
end

case options.display_mode
when "raw"
  puts status.to_json
when "tree"
  status.each do |version|
    puts "|-- #{version["label"]} (#{version["id"]})"
    version.each do |key, value|
      puts "|   |-- #{key}: #{value}"
    end
  end
end
