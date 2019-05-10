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
require_relative 'core/model/app'
require_relative 'core/base_tool2.rb'

include PatchKitTools::Model

module PatchKitTools
  class DownloadVersionSignaturesTool < PatchKitTools::BaseTool2
    attr_writer :secret, :api_key, :version, :output

    def initialize(argv = ARGV)
      super(argv, "download-version-signatures", "Downloads version signatures package.",
            "-s <secret> -a <api_key> -v <version> -o <output>")

      @secret = nil
      @api_key = nil
      @version = nil
      @output = nil
    end

    def parse_options
      super do |opts|
        opts.separator "Mandatory"

        opts.on("-s", "--secret <secret>",
          "application secret") do |secret|
          @secret = secret
        end

        opts.on("-a", "--api-key <api_key>",
          "user API key") do |api_key|
          @api_key = api_key
        end

        opts.on("-v", "--version <version>", Integer,
          "application version") do |version|
          @version = version
        end

        opts.on("-o", "--output <output>",
          "output file") do |output|
          @output = output
        end
      end
    end

    def execute
      check_if_option_exists(:secret, :api_key, :version, :output)

      app = App.find_by_secret!(@secret)
      version = Version.find_by_id!(app, @version)
      raise "Cannot find version: #{@version}" if version.nil?

      raise CommandLineError, "Output file exists: #{@output}" if File.exist? @output

      downloaded = 0
      content_size = nil
      progress_bar = nil

      while downloaded != content_size
        version.download_signatures(offset: downloaded) do |response|

          file = File.open(@output, 'ab')
          begin
            content_size ||= response.content_length
            raise "Content-Length not returned by the server." if content_size.nil?

            progress_bar = ProgressBar.new(content_size)

            response.read_body do |segment|
              file.write segment

              downloaded += segment.bytesize
              progress_bar.print(downloaded,
                "Downloading signature - %.2f MB out of %.2f MB" %
                [downloaded / 1024.0 / 1024.0, content_size / 1024.0 / 1024.0])
            end
          rescue EOFError => e
            puts "Error: #{e.message}"
          ensure
            file.close
          end

          if downloaded != content_size
            puts "Error while downloading signatures. Will try again in 5 seconds..."
            sleep 5
            break # makes sure to exit download_signatures block
          end
        end

      end # while

      progress_bar.print(content_size, "Signatures downloaded.", force: true)
    end
  end
end

if $0 == __FILE__
  PatchKitTools::execute_tool PatchKitTools::DownloadVersionSignaturesTool.new
end
