#!/usr/bin/env ruby

=begin
$META_START$
name: publish-version
summary: Publishes version to the world.
basic: false
class: PatchKitTools::PublishVersionTool
$META_END$
=end

require_relative 'core/patchkit_api.rb'
require_relative 'core/patchkit_tools.rb'
require_relative 'list_versions.rb'

module PatchKitTools
  class PublishVersionTool < PatchKitTools::BaseTool
    def initialize
      super("publish-version", "Publishes version.",
            "-s <secret> -a <api_key> -v <version>")
      self.draft = false
      self.wait_until_published = false
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

        opts.on("-v", "--version <version>", Integer,
          "version to publish") do |version|
          self.version = version
        end

        opts.separator ""

        opts.separator "Optional"

        opts.on("-d", "--draft",
                "publishes current draft version (overrides --version) (default: #{self.draft})") do
          self.draft = true
        end

        opts.on("-w", "--wait-until-published",
                "waits until version is published (default: #{self.wait_until_published})") do
          self.wait_until_published = true
        end
      end
    end

    def get_versions_list
      list_versions_tool = PatchKitTools::ListVersionsTool.new
      list_versions_tool.secret = self.secret
      list_versions_tool.api_key = self.api_key
      list_versions_tool.display_limit = 0
      list_versions_tool.sort_mode = "desc"

      list_versions_tool.execute

      list_versions_tool.versions_list
    end

    def fetch_draft_version_id
      version_list = get_versions_list
      return nil if version_list.empty?

      draft_version = version_list.find { |e| e['draft'] }
      return nil if draft_version.nil?
      draft_version['id']
    end

    def execute
      check_if_option_exists("secret")
      check_if_option_exists("api_key")
      check_if_option_exists("version") unless self.draft

      if self.draft
        self.version = fetch_draft_version_id
        if self.version.nil?
          raise CommandLineError, "Couldn't locate draft version"
        end
      end

      resource_name = "1/apps/#{self.secret}/versions/#{self.version}/publish?api_key=#{self.api_key}"

      puts "Publishing version..."

      PatchKitAPI::ResourceRequest.new(resource_name, nil, Net::HTTP::Put).get_object do
        puts "Version publish is pending!"
        PatchKitAPI.wait_until_version_published(self.secret, self.version) if self.wait_until_published
      end
    end
  end
end

if $0 == __FILE__
  PatchKitTools::execute_tool PatchKitTools::PublishVersionTool.new
end
