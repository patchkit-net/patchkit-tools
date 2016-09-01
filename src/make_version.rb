#!/usr/bin/env ruby

require_relative 'lib/patchkit_api.rb'
require_relative 'lib/patchkit_tools.rb'

options = PatchKitTools::Options.new("make-version", "Creates a version, generates a diff, uploads it and publishes.",
                                     "[-s <secret>] [-a <api_key>] [-l <label>] [-f <files>] [-c <changelog>]")

options.parse(__FILE__ != $0 ? $passed_args : ARGV) do |opts|
  opts.separator "Mandatory (if not supplied, program will ask for them)"

  opts.on("-s", "--secret <secret>",
    "application secret (if n)") do |secret|
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

  opts.on("-f", "--files <files>",
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

options.secret = options.ask_for("secret") if options.secret.nil?
options.error_argument_missing("secret") if options.secret.nil?

#options.api_key = options.ask_for("apikey") if options.api_key.nil?
#options.error_argument_missing("apikey") if options.api_key.nil?

#options.label = options.ask_for("label") if options.label.nil?
#options.error_argument_missing("label") if options.label.nil?

#options.files = options.ask_for("files") if options.files.nil?
#options.error_argument_missing("files") if options.files.nil?
#options.error_directory_not_exists("files") unless File.directory?(options.files)

puts PatchKitTools::run_ruby("#{File.dirname(__FILE__)}/list_versions.rb", "--secret", options.secret, "--displaymode", "raw")
