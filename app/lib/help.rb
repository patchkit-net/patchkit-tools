require_relative 'tools'

module PatchKitTools
  class Help
    def self.general
      str = "Usage: patchkit-tools [tool_name] [tool_arguments]\n\n"
      str << "Tool help: patchkit-tools [tool_name] --help\n\n"
      str << "Basic tools:\n"

      tools = Tools.parse_all
      tools.sort_by! { |t| t.name }
      tools.each do |tool|
        str << "    #{tool.name} - #{tool.summary}\n" if tool.basic?
      end

      str << "\nAdvanced tools:\n"
      tools.each do |tool|
        str << "    #{tool.name} - #{tool.summary}\n" unless tool.basic?
      end

      str << "\nGetting started: http://docs.patchkit.net/tools.html\n"
      str
    end
  end
end
