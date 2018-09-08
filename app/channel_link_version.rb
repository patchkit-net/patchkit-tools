=begin
$META_START$
name: channel-link-version
summary: Links channel to existing version.
basic: false
class: PatchKitTools::ChannelLinkVersion
$META_END$
=end

require_relative 'core/patchkit_api.rb'
require_relative 'core/patchkit_tools.rb'
require_relative 'core/base_tool2.rb'
require_relative 'core/model/app'
require_relative 'core/model/version'

module PatchKitTools
  class ChannelLinkVersion < PatchKitTools::BaseTool2
    include Model

    def initialize(argv = ARGV)
      super(argv, "channel-link-version", "Links channel to existing version.",
            "-s <secret> -a <api_key> -v <version> --group-secret <group_secret> --group-version <group_version>")
    end

    def parse_options
      super do |opts|
        opts.separator "Mandatory"

        opts.on("-s", "--secret <secret>", "application secret") { |v| @secret = v }
        opts.on("-a", "--api-key <api_key>", "user API key") { |v| @api_key = v }
        opts.on("-v", "--version <version>", Integer,
                "application version id") { |v| @version = v }
        opts.on("--group-secret <secret>", "group secret") { |v| @group_secret = v }
        opts.on("--group-version <version>", Integer,
                "group version id") { |v| @group_version = v }
      end
    end

    def execute
      check_if_option_exists(:secret, :api_key, :version, :group_secret, :group_version)

      app = App.find_by_secret!(@secret)
      version = Version.find_by_id!(app, @version)

      result = version.link_to!(source_app_secret: @group_secret, source_vid: @group_version)
      job_guid = result[:job_guid]

      PatchKitAPI.display_job_progress(job_guid)
    end
  end
end
