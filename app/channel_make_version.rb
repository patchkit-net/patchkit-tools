=begin
$META_START$
name: channel-make-version
summary: Creates a new channel version
basic: true
class: PatchKitTools::ChannelMakeVersionTool
$META_END$
=end

require_relative 'core/patchkit_api.rb'
require_relative 'core/patchkit_tools.rb'
require_relative 'core/base_tool2.rb'
require_relative 'core/model/app'
require_relative 'core/model/version'

module PatchKitTools
  class ChannelMakeVersionTool < PatchKitTools::BaseTool2
    include Model

    def initialize(argv = ARGV)
      super(argv, "channel-make-version", "Creates a new channel version.",
            "-s <secret> -a <api_key> -l <label>")

      @publish = false
      @group_version = nil
    end

    def parse_options
      super do |opts|
        opts.separator "Mandatory"

        opts.on("-a", "--api-key <api_key>", "user API key") { |v| @api_key = v }
        opts.on("-s", "--secret <secret>", "application secret") { |v| @secret = v }
        opts.on("-l", "--label <label>", "version label") { |v| @label = v }

        opts.separator "Optional"

        opts.on("-c", "--changelog <changelog>", "version changelog") do |changelog|
          @changelog = changelog
        end

        opts.on("-z", "--changelog-file <changelog_file>",
          "text file with version changelog") do |changelog_file|
          @changelog_file = changelog_file
        end

        opts.on("--group-version <version>", Integer,
                "group version id to link from") { |v| @group_version = v }
        opts.on("--latest-group-version", "link from latest group version") { @group_version = :latest }

        opts.on("-x", "--overwrite-draft", "overwrites existing draft") { @overwrite = true }

        opts.on("-p", "--publish", "publish/persist when done") { @publish = true }
      end
    end

    def execute
      check_if_option_exists(:secret, :api_key, :label)
      validate_api_key! if @api_key

      raise_error "not a channel" unless app.is_channel?

      group = app.group
      versions = group.published_versions

      source_version =
        if @group_version == :latest
          versions.max_by(&:id)
        elsif @group_version
          versions.find { |v| v.id.to_s == @group_version.to_s }
        else
          raise_error "Missing group version to import. Please specify one with --group-version or --latest-group-version."
        end

      raise_error "cannot find group version to import" if source_version.nil?

      if !draft_version.nil?
        if !@overwrite && !ask_yes_or_no("Draft version already exists. Its "\
          "contents will be overwritten. Proceed?", "y")
          exit
        end
      else
        create_draft_version!
      end

      draft_version.label = @label
      draft_version.changelog = changelog if changelog

      if @publish
        draft_version.publish_when_processed = true
        puts "This version will be published as soon as it gets processed."
      end

      draft_version.save!

      result = draft_version.link_to!(source_app_secret: group.secret, source_vid: source_version.id)
      job_guid = result[:job_guid]

      PatchKitAPI.display_job_progress(job_guid)
    end

    def app
      @app ||= App.find_by_secret!(@secret)
    end

    def draft_version
      @draft_version ||= app.versions.find(&:draft?)
    end

    def create_draft_version!
      @draft_version ||= Version.create(app, label: @label)
    end

    def changelog
      return if !@changelog && !@changelog_file
      return @changelog if @changelog
      File.read(@changelog_file)
    end
  end
end
