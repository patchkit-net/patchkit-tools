#!/usr/bin/env ruby

require_relative 'lib/patchkit_api.rb'
require_relative 'lib/patchkit_tools.rb'

DISPLAY_MODES = ["raw", "tree"]
DISPLAY_SORT_MODES = ["desc", "asc"]

options = PatchKitTools::Options.new("list-versions", "Lists application versions.",
                                     "-s <secret> [optional]")
options.display_mode = "tree"
options.display_limit = -1
options.display_sort_mode = "desc"

options.parse(__FILE__ != $0 ? $passed_args : ARGV) do |opts|
  opts.separator "Mandatory"

  opts.on("-s", "--secret <secret>",
    "application secret") do |secret|
    options.secret = secret
  end

  opts.separator ""

  opts.separator "Optional"

  opts.on("-a", "--apikey <api_key>",
    "user API key (when supplied draft version is also listed)") do |api_key|
    options.api_key = api_key
  end

  opts.on("-d", "--displaymode <display_mode>",
    "display mode; #{DISPLAY_MODES.join(", ")} (default: #{options.display_mode})") do |display_mode|
      options.display_mode = display_mode
  end
  opts.on("-l", "--displaylimit <display_limit>", Integer,
    "limit of displayed versions; -1 = infinite (default: #{options.display_limit})") do |display_limit|
      options.display_limit = display_limit
  end
  opts.on("-m", "--displaysortmode <display_sort_mode>",
    "display sort type; #{DISPLAY_SORT_MODES.join(", ")} (default: #{options.display_sort_mode})") do |display_sort_mode|
      options.display_sort_mode = display_sort_mode
  end
end

options.error_argument_missing("secret") if options.secret.nil?
options.error_invalid_argument_value("displaymode") if !DISPLAY_MODES.include? options.display_mode
options.error_invalid_argument_value("displaysortmode") if !DISPLAY_SORT_MODES.include? options.display_sort_mode

resource_name = "1/apps/#{options.secret}/versions"

# Optionally add API Key to the request
resource_name += "?api_key=#{options.api_key}" unless options.api_key.nil?

# Get request result
status = PatchKitAPI::ResourceRequest.new(resource_name).get_object

# Sort results
status = status.sort_by {|version| options.display_sort_mode == "asc" ? version["id"] : -version["id"]}

# Limit versions if display limit was supplied
if(options.display_limit > -1)
  status = status[0,[options.display_limit, status.length].min]
end

# Display data
case options.display_mode
when "raw"
  puts status.to_json
when "tree"
  status.each do |version|
    # Display version header
    puts "|-- #{version["label"]} (#{version["id"]})"

    # Display version properites
    version.each do |key, value|
      puts "|   |-- #{key}: #{value}"
    end
  end
end
