#!/usr/bin/env ruby

require_relative 'lib/patchkit_api.rb'
require_relative 'lib/patchkit_tools.rb'

options = PatchKitTools::Options.new("create-version", "Creates new application version (draft).",
                                     "-s <secret> -a <api_key> -l <label> [-c <changelog>]")

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

  opts.on("-l", "--label <label>",
    "version label") do |label|
    options.label = label
  end

  opts.separator ""

  opts.separator "Optional"

  opts.on("-c", "--changelog <changelog>",
    "version changelog") do |changelog|
    options.changelog = changelog
  end
end

options.error_argument_missing("secret") if options.secret.nil?
options.error_argument_missing("apikey") if options.api_key.nil?
options.error_argument_missing("label") if options.label.nil?

resource_name = "1/apps/#{options.secret}/versions?api_key=#{options.api_key}"

resource_form = {
  "label" => options.label,
}

# Add changelog to request only if it was passed in options
resource_form["changelog"] = options.changelog unless options.changelog.nil?

puts "Sending request..."
result = PatchKitAPI::ResourceRequest.new(resource_name, resource_form, Net::HTTP::Post).get_object
puts "Result: #{result}"
puts "Done!"
