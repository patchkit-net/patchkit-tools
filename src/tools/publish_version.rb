#!/usr/bin/env ruby

require_relative 'lib/patchkit_api.rb'
require_relative 'lib/patchkit_tools.rb'

options = PatchKitTools::Options.new("publish_version", "Publishes version")

options.parse(__FILE__ != $0 ? $passed_args : ARGV) do |opts|
  opts.on("-s", "--secret SECRET",
    "application secret") do |secret|
    options.secret = secret
  end

  opts.on("-a", "--apikey API_KEY",
    "user API key") do |api_key|
    options.api_key = api_key
  end

  opts.on("-v", "--version VERSION", Integer,
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
