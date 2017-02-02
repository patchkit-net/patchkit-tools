require_relative 'help'
require_relative 'tools'

include PatchKitTools

if ARGV[0].nil? || ARGV[0] == '--help'
  puts Help.general
else
  tools = Tools.parse_all
  tool = tools.find { |tool| tool.name == ARGV[0] }
  if !tool.nil?
    tool.execute
  else
    puts "Tool not found: #{ARGV[0]}"
    exit 1
  end
end
