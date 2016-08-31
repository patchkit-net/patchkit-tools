#!/usr/bin/env ruby

require_relative 'lib/patchkit_api.rb'
require_relative 'lib/patchkit_tools.rb'

options = PatchKitTools::Options.new("update-version", "Updates properties of the version.",
                                     "-s <secret> -a <api_key> -v <version> [properties]")

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
    "application version") do |version|
    options.version = version
  end

  opts.separator "Properties"

  opts.separator ""

  opts.on("-l", "--label <label>",
    "version label") do |label|
    options.label = label
  end

  opts.on("-c", "--changelog <changelog>",
    "version changelog") do |changelog|
    options.changelog = changelog
  end
end

options.error_argument_missing("secret") if options.secret.nil?
options.error_argument_missing("apikey") if options.api_key.nil?
options.error_argument_missing("version") if options.version.nil?

resource_name = "1/apps/#{options.secret}/versions/#{options.version}?api_key=#{options.api_key}"
resource_form = {}

resource_form["label"] = options.label unless options.label.nil?
resource_form["changelog"] = options.changelog unless options.changelog.nil?

puts "Updating..."

PatchKitAPI::ResourceRequest.new(resource_name, resource_form, Net::HTTP::Patch).get_object do |object|
  puts "Result: #{object}"
  puts "Done!"
end
