#!/usr/bin/env ruby

=begin
$META_START$
name: publish-version
summary: Publishes version to the world.
basic: false
class: PatchKitTools::PublishVersionTool
$META_END$
=end

require_relative 'lib/patchkit_api.rb'
require_relative 'lib/patchkit_tools.rb'

module PatchKitTools
  class PublishVersionTool < PatchKitTools::BaseTool
    def initialize
      super("publish-version", "Publishes version.",
            "-s <secret> -a <api_key> -v <version>")
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
      end
    end

    def execute
      check_if_option_exists("secret")
      check_if_option_exists("api_key")
      check_if_option_exists("version")

      resource_name = "1/apps/#{self.secret}/versions/#{self.version}/publish?api_key=#{self.api_key}"

      puts "Publishing version..."

      PatchKitAPI::ResourceRequest.new(resource_name, nil, Net::HTTP::Put).get_object do |object|
        puts "Version has been published!"
      end
    end
  end
end

if $0 == __FILE__
  PatchKitTools::execute_tool PatchKitTools::PublishVersionTool.new
end
