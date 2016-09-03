#!/usr/bin/env ruby

require_relative 'lib/patchkit_api.rb'
require_relative 'lib/patchkit_tools.rb'

module PatchKitTools
  class ListVersionsTool < PatchKitTools::Tool
    DISPLAY_MODES = ["raw", "tree"]
    DISPLAY_SORT_MODES = ["desc", "asc"]

    def initialize
      super("list-versions",
            "Lists application versions. Returned data - JSON with list of downloaded versions (if display mode is set to raw).",
            "-s <secret> [optional]")

      self.display_mode = "tree"
      self.display_limit = -1
      self.display_sort_mode = "desc"
    end
  end
end



tool = PatchKitTools::Tool.new


tool.parse_arguments do |opts|
  opts.separator "Mandatory"

  opts.on("-s", "--secret <secret>",
    "application secret") do |secret|
    tool.secret = secret
  end

  opts.separator ""

  opts.separator "Optional"

  opts.on("-a", "--apikey <api_key>",
    "user API key (when supplied draft version is also listed)") do |api_key|
    tool.api_key = api_key
  end

  opts.on("-d", "--displaymode <display_mode>",
    "display mode; #{DISPLAY_MODES.join(", ")} (default: #{tool.display_mode})") do |display_mode|
      tool.display_mode = display_mode
  end

  opts.on("-l", "--displaylimit <display_limit>", Integer,
    "limit of displayed versions; -1 = infinite (default: #{tool.display_limit})") do |display_limit|
      tool.display_limit = display_limit
  end

  opts.on("-m", "--displaysortmode <display_sort_mode>",
    "display sort type; #{DISPLAY_SORT_MODES.join(", ")} (default: #{tool.display_sort_mode})") do |display_sort_mode|
      tool.display_sort_mode = display_sort_mode
  end
end

tool.check_if_argument_exists("secret")
tool.check_if_valid_argument_value("display_mode", DISPLAY_MODES)
tool.check_if_valid_argument_value("display_sort_mode", DISPLAY_SORT_MODES)

tool.execute do
  resource_name = "1/apps/#{tool.secret}/versions"

  # Optionally add API Key to the request
  resource_name += "?api_key=#{tool.api_key}" unless tool.api_key.nil?

  # Get request result
  results = PatchKitAPI::ResourceRequest.new(resource_name).get_object

  # Sort results
  results = results.sort_by {|version| tool.display_sort_mode == "asc" ? version["id"] : -version["id"]}

  # Limit versions if display limit was supplied
  if(tool.display_limit > -1)
    results = results[0,[tool.display_limit, results.length].min]
  end

  # Display data
  case tool.display_mode
  when "raw"
    tool.print_data results.to_json
  when "tree"
    results.each do |version|
      # Display version header
      tool.print_data "|-- #{version["label"]} (#{version["id"]})"

      # Display version properites
      version.each do |key, value|
        tool.print_data "|   |-- #{key}: #{value}"
      end
    end
  end
end
