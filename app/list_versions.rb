#!/usr/bin/env ruby

=begin
$META_START$
name: list-version
summary: Lists application versions.
basic: false
class: PatchKitTools::ListVersionsTool
$META_END$
=end

require_relative 'core/patchkit_api.rb'
require_relative 'core/patchkit_tools.rb'

module PatchKitTools
  class ListVersionsTool < PatchKitTools::BaseTool
    attr_reader :versions_list

    SORT_MODES = ["desc", "asc"]

    def initialize
      super("list-versions",
            "Lists application versions.",
            "-s <secret> [optional]")

      self.display_limit = -1
      self.sort_mode = "desc"
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

        opts.on("-a", "--apikey <apikey>",
          "user API key (when supplied draft version is also listed)") do |api_key|
          self.api_key = api_key
        end

        opts.on("-l", "--displaylimit <display_limit>", Integer,
          "limit of displayed versions; -1 = infinite (default: #{self.display_limit})") do |display_limit|
            self.display_limit = display_limit
        end

        opts.on("-m", "--sortmode <sort_mode>",
          "sort mode; #{SORT_MODES.join(", ")} (default: #{self.sort_mode})") do |sort_mode|
            self.sort_mode = sort_mode
        end
      end
    end

    def execute
      check_if_option_exists("secret")
      check_if_valid_option_value("sort_mode", SORT_MODES)

      resource_name = "1/apps/#{self.secret}/versions"

      resource_name += "?api_key=#{self.api_key}" unless self.api_key.nil?

      results = PatchKitAPI::ResourceRequest.new(resource_name).get_object
      
      results = results.sort_by {|version| self.sort_mode == "asc" ? version["id"] : -version["id"]}

      @versions_list = results

      if(self.display_limit > -1)
        results = results[0,[self.display_limit, results.length].min]
      end

      results.each do |version|
        puts "|-- #{version["label"]} (#{version["id"]})"

        version.each do |key, value|
          puts "|   |-- #{key}: #{value}"
        end
      end
    end
  end
end

if $0 == __FILE__
  PatchKitTools::execute_tool PatchKitTools::ListVersionsTool.new
end
