#!/usr/bin/env ruby

require_relative 'lib/patchkit_api.rb'
require_relative 'lib/patchkit_tools.rb'

options = PatchKitTools::Options.new("update-version", "Updates properties of the version")

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
    "application version") do |version|
    options.version = version
  end

  opts.on("", "--label [LABEL]",
    "version label") do |label|
    options.label = label
  end

  opts.on("", "--changelog [CHANGELOG]",
    "version changelog") do |changelog|
    options.changelog = changelog
  end
end

options.error_argument_missing("secret") if options.secret.nil?
options.error_argument_missing("apikey") if options.api_key.nil?
options.error_argument_missing("version") if options.version.nil?
options.error("You must request at least one change") if options.label.nil? && options.changelog.nil?

raise "Not implemented"
