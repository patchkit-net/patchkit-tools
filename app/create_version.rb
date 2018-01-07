#!/usr/bin/env ruby


=begin
$META_START$
name: create-version
summary: Creates new version entry on the server.
basic: false
class: PatchKitTools::CreateVersionTool
$META_END$
=end

require_relative 'core/patchkit_api.rb'
require_relative 'core/patchkit_tools.rb'

module PatchKitTools
  class CreateVersionTool < PatchKitTools::BaseTool
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
    end

    def execute
      check_if_option_exists("secret")
      check_if_option_exists("api_key")
      check_if_option_exists("label")

      resource_name = "1/apps/#{self.secret}/versions?api_key=#{self.api_key}"

      resource_form = {
        "label" => self.label,
      }

      resource_form["changelog"] = self.changelog unless self.changelog.nil?

      puts "Creating version..."

      result = PatchKitAPI::ResourceRequest.new(resource_name, resource_form, Net::HTTP::Post).get_object

      @created_version_id = result["id"]

      puts "A new version of id #{@created_version_id} has been created!"
    end
  end
end

if $0 == __FILE__
  PatchKitTools::execute_tool PatchKitTools::CreateVersionTool.new
end
