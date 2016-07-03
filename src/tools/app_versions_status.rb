#!/usr/bin/env ruby

require_relative 'lib/patchkit_api.rb'
require_relative 'lib/patchkit_tools.rb'

DISPLAY_MODES = ["raw", "tree"]
DISPLAY_SORTS = ["desc", "asc"]

options = PatchKitTools::Options.new
options.display_mode = "tree"
options.display_limit = -1
options.display_sort = "desc"

options.parse("app-versions-tools", __FILE__ != $0 ? $passed_args : ARGV) do |opts|
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
end

options.error_argument_missing("secret") if options.secret.nil?
options.error_argument_invaild_value("displaymode") if !DISPLAY_MODES.include? options.display_mode
options.error_argument_invaild_value("displaysort") if !DISPLAY_SORTS.include? options.display_sort

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
