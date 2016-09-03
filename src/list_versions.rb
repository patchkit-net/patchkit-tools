#!/usr/bin/env ruby

require_relative 'lib/patchkit_api.rb'
require_relative 'lib/patchkit_tools.rb'

module PatchKitTools
  class ListVersionsTool < PatchKitTools::Tool
    attr_reader: versions_list

    DISPLAY_MODES = ["raw", "tree"]
    DISPLAY_SORT_MODES = ["desc", "asc"]

    def initialize
      super("list-versions",
            "Lists application versions.",
            "-s <secret> [optional]")

      self.display_mode = "tree"
      self.display_limit = -1
      self.display_sort_mode = "desc"
    end

    def parse_options
      super do |opts|
        opts.separator "Mandatory"

        opts.on("-s", "--secret <secret>",
          "application secret") do |secret|
          self.secret = secret
        end

        opts.separator ""

        opts.separator "Optional"

        opts.on("-a", "--apikey <api_key>",
          "user API key (when supplied draft version is also listed)") do |api_key|
          self.api_key = api_key
        end

        opts.on("-d", "--displaymode <display_mode>",
          "display mode; #{DISPLAY_MODES.join(", ")} (default: #{self.display_mode})") do |display_mode|
            self.display_mode = display_mode
        end

        opts.on("-l", "--displaylimit <display_limit>", Integer,
          "limit of displayed versions; -1 = infinite (default: #{self.display_limit})") do |display_limit|
            self.display_limit = display_limit
        end

        opts.on("-m", "--displaysortmode <display_sort_mode>",
          "display sort type; #{DISPLAY_SORT_MODES.join(", ")} (default: #{self.display_sort_mode})") do |display_sort_mode|
            self.display_sort_mode = display_sort_mode
        end
      end
    end

    def execute
      check_options

      resource_name = "1/apps/#{self.secret}/versions"

      # Optionally add API Key to the request
      resource_name += "?api_key=#{self.api_key}" unless self.api_key.nil?

      # Get request result
      results = PatchKitAPI::ResourceRequest.new(resource_name).get_object

      # Sort results
      results = results.sort_by {|version| self.display_sort_mode == "asc" ? version["id"] : -version["id"]}

      # Limit versions if display limit was supplied
      if(self.display_limit > -1)
        results = results[0,[self.display_limit, results.length].min]
      end

      # Display data
      case self.display_mode
      when "raw"
        puts results.to_json
      when "tree"
        results.each do |version|
          # Display version header
          puts "|-- #{version["label"]} (#{version["id"]})"

          # Display version properites
          version.each do |key, value|
            puts "|   |-- #{key}: #{value}"
          end
        end
      end

      @versions_list = results
    end

  private
    def check_options
      check_if_option_exists("secret")
      check_if_valid_option_value("display_mode", DISPLAY_MODES)
      check_if_valid_option_value("display_sort_mode", DISPLAY_SORT_MODES)
    end
  end
end

if $0 == __FILE__
  PatchKitTools::execute_tool PatchKitTools::ListVersionsTool.new
end
