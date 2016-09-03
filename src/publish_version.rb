#!/usr/bin/env ruby

require_relative 'lib/patchkit_api.rb'
require_relative 'lib/patchkit_tools.rb'

module PatchKitTools
  class PublishVersionTool < PatchKitTools::Tool
    def initialize
      super("publish-version", "Publishes version.",
            "-s <secret> -a <api_key> -v <version>")
    end
  end
end

options = PatchKitTools::Options.new(

options.parse(__FILE__ != $0 ? $passed_args : ARGV) do |opts|
  opts.separator "Mandatory"

  opts.on("-s", "--secret <secret>",
    "application secret") do |secret|
    options.secret = secret
  end

  opts.on("-a", "--apikey <api_key>",
    "user API key") do |api_key|
    options.api_key = api_key
  end

  opts.on("-v", "--version <version>", Integer,
    "version to publish") do |version|
    options.version = version
  end
end

options.error_argument_missing("secret") if options.secret.nil?
options.error_argument_missing("apikey") if options.api_key.nil?
options.error_argument_missing("version") if options.version.nil?

resource_name = "1/apps/#{options.secret}/versions/#{options.version}/publish?api_key=#{options.api_key}"

puts "Publishing veresion..."

PatchKitAPI::ResourceRequest.new(resource_name, nil, Net::HTTP::Put).get_object do |object|
  puts "Result: #{object}"
  puts "Done!"
end
