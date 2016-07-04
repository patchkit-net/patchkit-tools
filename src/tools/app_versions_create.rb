#!/usr/bin/env ruby

require_relative 'lib/patchkit_api.rb'
require_relative 'lib/patchkit_tools.rb'

options = PatchKitTools::Options.new

options.parse("app-versions-update", __FILE__ != $0 ? $passed_args : ARGV) do |opts|
  opts.on("-s", "--secret SECRET",
    "application secret") do |secret|
    options.secret = secret
  end

  opts.on("-a", "--apikey API_KEY",
    "user API key") do |api_key|
    options.api_key = api_key
  end

  opts.on("-l", "--label LABEL",
    "version label") do |label|
    options.label = label
  end

  opts.on("-c", "--changelog [CHANGELOG]",
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
resource_form["changelog"] = options.changelog unless options.changelog.nil?

puts PatchKitAPI::ResourceRequest.new(resource_name, resource_form, Net::HTTP::Post).get_object
