#!/usr/bin/env ruby

=begin
$META_START$
name: download-version-signatures
summary: Downloads version signatures package.
basic: false
class: PatchKitTools::DownloadVersionSignaturesTool
$META_END$
=end

require_relative 'core/patchkit_api.rb'
require_relative 'core/patchkit_tools.rb'

module PatchKitTools
  class DownloadVersionSignaturesTool < PatchKitTools::BaseTool
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

      downloaded = 0
      content_size = -1
      progress_bar = nil

      while downloaded != content_size

        PatchKitAPI::ResourceRequest.new("1/apps/#{self.secret}/versions/#{self.version}/signatures?api_key=#{self.api_key}").get_response do |response|
          file = File.open(self.output, 'wb')
          begin
            content_size = response.content_length
            progress_bar = ProgressBar.new(content_size)
            downloaded = 0

            response.read_body do |segment|
              file.write segment

              downloaded += segment.bytesize
              progress_bar.print(downloaded, "Downloading signature - %.2f MB out of %.2f MB" % [downloaded / 1024.0 / 1024.0, content_size / 1024.0 / 1024.0])
            end
            
          ensure
            file.close
          end

          if downloaded != content_size
            puts "Error while downloading signatures. Will try again in 30 seconds..."
            sleep 30
          end
        end

      end # while

      progress_bar.print(content_size, "Signatures downloaded.")
    end
  end
end

if $0 == __FILE__
  PatchKitTools::execute_tool PatchKitTools::DownloadVersionSignaturesTool.new
end
