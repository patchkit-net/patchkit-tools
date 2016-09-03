#!/usr/bin/env ruby

require_relative 'lib/patchkit_api.rb'
require_relative 'lib/patchkit_tools.rb'

module PatchKitTools
  class CreateVersionTool < PatchKitTools::Tool
    attr_reader :created_version_id

    def initialize
      super("create-version",
            "Creates new application version (draft). Note that only one draft version can exists at the same time.",
            "-s <secret> -a <api_key> -l <label> [-c <changelog>]")
    end

    def parse_options
      super do |opts|
        opts.separator "Mandatory"

        opts.on("-s", "--secret <secret>",
          "application secret") do |secret|
          self.secret = secret
        end

        opts.on("-a", "--apikey <api_key>",
          "user API key") do |api_key|
          self.api_key = api_key
        end

        opts.on("-l", "--label <label>",
          "version label") do |label|
          self.label = label
        end

        opts.separator ""

        opts.separator "Optional"

        opts.on("-c", "--changelog <changelog>",
          "version changelog") do |changelog|
          self.changelog = changelog
        end
      end

      def execute
        check_if_option_exists("secret")
        check_if_option_exists("api_key")
        check_if_option_exists("label")

        resource_name = "1/apps/#{self.secret}/versions?api_key=#{self.api_key}"

        resource_form = {
          "label" => self.label,
        }

        # Add changelog to request only if it was passed in options
        resource_form["changelog"] = self.changelog unless self.changelog.nil?

        puts "Creating version..."
        result = PatchKitAPI::ResourceRequest.new(resource_name, resource_form, Net::HTTP::Post).get_object
        puts "A new version of id #{result["id"]} has been created!"

        @created_version_id = result["id"]
      end
    end
  end
end

if $0 == __FILE__
  PatchKitTools::execute_tool PatchKitTools::CreateVersionTool.new
end
