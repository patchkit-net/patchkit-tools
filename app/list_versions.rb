#!/usr/bin/env ruby

=begin
$META_START$
name: list-versions
summary: Lists application versions.
basic: false
class: PatchKitTools::ListVersionsTool
$META_END$
=end

require_relative 'core/patchkit_api.rb'
require_relative 'core/patchkit_tools.rb'
require_relative 'core/base_tool2.rb'

module PatchKitTools
  class ListVersionsTool < PatchKitTools::BaseTool2
    attr_reader :versions_list
    attr_writer :secret, :api_key, :display_limit, :sort_mode

    SORT_MODES = ["desc", "asc"]

    def initialize(argv = ARGV)
      super(argv, "list-versions", "Lists application versions.", "-s <secret> [optional]")
      @display_limit = -1
      @sort_mode = "desc"
      @format = :yaml
    end

    def parse_options
      super do |opts|
        opts.separator "Mandatory"

        opts.on("-s", "--secret <secret>", "application secret") { |v| @secret = v }

        opts.separator ""
        opts.separator "Optional"

        opts.on("-a", "--api-key <api_key>",
                "user API key (when supplied draft version is also listed)") { |v| @api_key = v }

        opts.on("-l", "--display-limit <display_limit>", Integer,
                "limit of displayed versions; -1 = infinite (default: #{@display_limit})") do |v|
          @display_limit = v
        end

        opts.on("-m", "--sort-mode <sort_mode>",
                "sort mode; #{SORT_MODES.join(", ")} (default: #{@sort_mode})") do |v|
          @sort_mode = v
        end

        opts.on('-f', '--format <format>', 'output format (default: yaml, available: yaml, json)') do |v|
          @format = v.to_sym
        end
      end
    end

    def execute
      check_if_option_exists("secret")
      check_if_valid_option_value("sort_mode", SORT_MODES)

      resource_name = "1/apps/#{@secret}/versions"
      resource_name << "?api_key=#{@api_key}" unless @api_key.nil?

      results = PatchKitAPI.get(resource_name)
      results = results.sort_by {|version| @sort_mode == "asc" ? version[:id] : -version[:id]}

      @versions_list = results

      results = results[0, [@display_limit, results.length].min] if @display_limit > -1

      puts case @format
             when :yaml
               YAML.dump(results)
             when :json
               JSON.pretty_generate(results)
             else
               raise "unknown format: #{@format}"
             end

      # results.each do |version|
      #   puts "|-- #{version[:label]} (#{version[:id]})"

      #   version.each do |key, value|
      #     puts "|   |-- #{key}: #{value}"
      #   end
      # end
    end
  end
end

if $0 == __FILE__
  PatchKitTools::execute_tool PatchKitTools::ListVersionsTool.new
end
