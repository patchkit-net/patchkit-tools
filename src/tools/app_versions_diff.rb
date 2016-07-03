#!/usr/bin/env ruby

require_relative 'lib/patchkit_api.rb'
require_relative 'lib/patchkit_tools.rb'
require_relative 'lib/zip_helper.rb'

options = PatchKitTools::Options.new

options.parse("app-versions-diff", __FILE__ != $0 ? $passed_args : ARGV) do |opts|
  opts.on("-s", "--signature SIGNATURE_FILE",
    "file with previous version signatures",
    "read more - type 'patchkit-tools app-versions-signature --help'") do |signature|
    options.signature = signature
  end

  opts.on("-f", "--files FILES_DIRECTORY",
    "directory with the newest version files") do |files|
    options.files = files
  end

  opts.on("-o", "--output OUTPUT_FILE",
    "output file") do |output|
    options.output = output
  end
end

options.error_argument_missing("signature") if options.signature.nil?
options.error_argument_missing("files") if options.files.nil?
options.error_argument_missing("output") if options.output.nil?

FileUtils.mkdir "diff_temp" unless File.directory?("diff_temp")

begin
  unzip(options.signature, "diff_temp/signature")
ensure
  #FileUtils.rm_rf "diff_temp"
end
