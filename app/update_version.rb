#!/usr/bin/env ruby

=begin
$META_START$
name: update-version
summary: Updates version properties.
basic: false
class: PatchKitTools::UpdateVersionTool
$META_END$
=end

require_relative 'core/patchkit_api.rb'
require_relative 'core/patchkit_tools.rb'

module PatchKitTools
  class UpdateVersionTool < PatchKitTools::BaseTool
    def initialize
      super("update-version", "Updates properties of the version.",
            "-s <secret> -a <api_key> -v <version> [properties]")
    end

    def parse_options
      super do |opts|
        opts.separator "Mandatory"

        opts.on("-s", "--secret <secret>",
          "application secret") do |secret|
          self.secret = secret
        end

        opts.on("-a", "--api-key <api_key>",
          "user API key") do |api_key|
          self.api_key = api_key
        end

        opts.on("-v", "--version <version>", Integer,
          "application version") do |version|
          self.version = version
        end

        opts.separator ""

        opts.separator "Properties (at least one is required)"

        opts.on("-l", "--label <label>",
          "version label") do |label|
          self.label = label
        end

        opts.on("-c", "--changelog <changelog>",
          "version changelog") do |changelog|
          self.changelog = changelog
        end

        opts.on("-z", "--changelog-file <changelog_file>",
          "text file with version changelog") do |changelog_file|
          self.changelog_file = changelog_file
        end
      end
    end

    def execute
      check_if_option_exists("secret")
      check_if_option_exists("api_key")
      check_if_option_exists("version")

      raise "At least one property is required" if self.label.nil? && self.changelog.nil? && self.changelog_file.nil?

      request_path = "1/apps/#{self.secret}/versions/#{self.version}?api_key=#{self.api_key}"
      form = {}

      form[:label] = self.label unless self.label.nil?
      form[:changelog] = self.changelog unless self.changelog.nil?
      form[:changelog] = File.open(self.changelog_file, 'rb') { |f| f.read } unless self.changelog_file.nil?

      puts "Updating..."

      PatchKitAPI.patch(request_path, params: form)
    end
  end
end

if $0 == __FILE__
  PatchKitTools::execute_tool PatchKitTools::UpdateVersionTool.new
end
