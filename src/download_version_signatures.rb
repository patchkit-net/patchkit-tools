#!/usr/bin/env ruby

require_relative 'lib/patchkit_api.rb'
require_relative 'lib/patchkit_tools.rb'

module PatchKitTools
  class DownloadVersionSignaturesTool < PatchKitTools::Tool
    def initialize
      super("download-version-signatures", "Downloads version signatures package.",
            "-s <secret> -a <api_key> -v <version> -o <output>")
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
          "application version") do |version|
          self.version = version
        end

        opts.on("-o", "--output <output>",
          "output file") do |output|
          self.output = output
        end
      end
    end

    def execute
      check_if_option_exists("secret")
      check_if_option_exists("api_key")
      check_if_option_exists("version")
      check_if_option_exists("output")

      PatchKitAPI::ResourceRequest.new("1/apps/#{self.secret}/versions/#{self.version}/signatures?api_key=#{self.api_key}").get_response do |response|
        file = File.open(self.output, 'wb')
        begin
          progress_bar = ProgressBar.new(response.content_length)
          total_length = 0.0
          response.read_body do |segment|
            file.write segment

            total_length += segment.length
            progress_bar.print(total_length, "Downloading signature - #{(total_length / 1024.0 / 1024.0).round(2)} MB out of #{(response.content_length / 1024.0 / 1024.0).round(2)} MB")
          end
          progress_bar.print(response.content_length, "Signatures downloaded.")
        ensure
          file.close
        end
      end
    end
  end
end

if $0 == __FILE__
  PatchKitTools::execute_tool PatchKitTools::DownloadVersionSignaturesTool.new
end
