require_relative 'help'
require_relative 'tools'
require_relative 'patchkit_api'
require_relative 'patchkit_tools'
require_relative 'version_info'

include PatchKitTools

def check_version!
  vi = VersionInfo.fetch
  unless vi.min_supported?
    puts "ERROR: This PatchKit Tools version is no longer supported and won't work correctly. "\
         "Please upgrade to newest release that can be found at "\
         "http://docs.patchkit.net/tools.html."
    exit 1
  end

  unless vi.latest?
    puts "WARNING: New release (#{vi.latest}) of PatchKit Tools is available."
    puts "Please visit http://docs.patchkit.net/tools.html for the upgrade instructions."
    puts ""
  end
rescue => e
  puts "WARNING: Unable to fetch PatchKit Tools version information: #{e.message}"
  puts ""
end

if ARGV[0].nil? || ARGV[0] == '--help'
  puts Help.general
elsif ARGV[0] == '--version'
  puts PatchKitTools::VERSION
else
  check_version!

  tools = Tools.parse_all
  tool = tools.find { |tool| tool.name == ARGV[0] }
  if !tool.nil?
    tool.execute
  else
    puts "Tool not found: #{ARGV[0]}"
    exit 1
  end
end
