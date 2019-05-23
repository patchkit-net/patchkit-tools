#!/usr/bin/env ruby

=begin
$META_START$
name: make-version
summary: Builds, uploads and optionally publshes a new version.
basic: true
class: PatchKitTools::MakeVersionTool
$META_END$
=end

require_relative 'core/patchkit_tools.rb'
require_relative 'core/base_tool2.rb'
require_relative 'content_version.rb'
require_relative 'diff_version.rb'
require_relative 'download_version_signatures.rb'
require_relative 'publish_version.rb'
require_relative 'update_version.rb'
require_relative 'upload_version.rb'
require_relative 'core/model/app'

include PatchKitTools::Model

module PatchKitTools
  class MakeVersionTool < PatchKitTools::BaseTool2
    def initialize(argv = ARGV)
      super(argv, "make-version", "Creates and uploads a complete version with optional publishing.",
            "[-s <secret>] [-a <api_key>] [-l <label>] [-f <files>] [-c <changelog>]")

      @label = nil
      @publish = false
      @overwrite_draft = false
      @changelog = nil
      @changelog_file = nil
      @files = nil
      @import_copy_label = false
      @import_copy_changelog = false
    end

    def parse_options
      super do |opts|
        opts.separator "Mandatory"

        opts.on("-s", "--secret <secret>", "application secret") do |secret|
          @secret = secret
        end

        opts.on("-a", "--api-key <api_key>", "user API key") do |api_key|
          @api_key = api_key
        end

        opts.on("-l", "--label <label>", "version label") do |label|
          @label = label
        end

        opts.separator ""
        opts.separator "Provide either -f or --import* parameters"

        opts.on("-f", "--files <files>", "path to version files directory") do |files|
          @files = files
        end

        opts.on("--import-app-secret <secret>", 'secret of source application') do |secret|
          @import_app_secret = secret
        end

        opts.on("--import-version <id>", Integer, 'id of source version') do |vid|
          @import_version_vid = vid
        end

        opts.separator ""
        opts.separator "Optional"

        opts.on("-p", "--publish", "publish after finished") { @publish = true }

        opts.on("-c", "--changelog <changelog>",
          "version changelog") do |changelog|
          @changelog = changelog
        end

        opts.on("-z", "--changelog-file <changelog_file>",
          "text file with version changelog") do |changelog_file|
          @changelog_file = changelog_file
        end

        opts.on("-x", "--overwrite-draft",
          "should draft version be overwritten if it already exists (default: #{@overwrite_draft})") do |overwrite_draft|
          @overwrite_draft = true
        end

        opts.on("--import-copy-label", 'copy label from source version') do
          @import_copy_label = true
        end

        opts.on("--import-copy-changelog", Integer, 'copy changelog from source version') do
          @import_copy_changelog = true
        end
      end
    end

    def execute
      interactive_ask if interactive?
      validate_input!

      validate_source_version! unless mode_files?

      if !draft_version.nil?
        if !@overwrite_draft && !ask_yes_or_no("Draft version already exists. Its "\
          "contents will be overwritten. Proceed?", "y")
          exit
        end
      else
        create_draft_version!
      end

      update_draft_version_details!

      if mode_files?
        upload_files!
      else
        import_version!(app_secret: @import_app_secret, vid: @import_version_vid)
      end

      if @publish
        publish_version!
        puts "This version will be published as soon as it gets processed."
      end

      puts "Everything here is done! You're now safe to quit (CTRL+C) or close your console window."
      puts
      puts "Processing:"

      PatchKitAPI.display_job_progress(@processing_job_guid)
      validate_processed!
    end

    def validate_source_version!
      raise_error "Source version cannot be imported" unless source_version.can_be_imported?
    end

    def source_app
      raise "invalid mode" unless mode_import?
      @source_app ||= App.find_by_secret!(@import_app_secret)
    end

    def source_version
      raise "invalid mode" unless mode_import?
      @source_version ||= Version.find_by_id!(source_app, @import_version_vid)
    end

    def update_draft_version_details!
      draft_version.label = target_label
      draft_version.changelog = target_changelog unless target_changelog.nil?
      draft_version.save!
    end

    def create_draft_version!
      self.draft_version = Version.create(app, label: target_label)
    end

    def target_label
      @label ||= if mode_import? && @import_copy_label
                   source_version.label
                 else
                   @label
                 end
    end

    def target_changelog
      @changelog ||= if mode_import? && @import_copy_changelog
                       source_version.changelog
                     elsif !@changelog_file.nil?
                       File.read(@changelog_file)
                     else
                       @changelog
                     end
    end

    def upload_version_content
      Dir.mktmpdir do |temp_dir|
        content_package = "#{temp_dir}/#{@secret}_content_#{draft_version_id}.zi_"

        content_version_tool = PatchKitTools::ContentVersionTool.new
        content_version_tool.files = @files
        content_version_tool.content = content_package

        content_version_tool.execute

        upload_version_content_tool = PatchKitTools::UploadVersionTool.new
        upload_version_content_tool.secret = @secret
        upload_version_content_tool.api_key = @api_key
        upload_version_content_tool.version = draft_version_id
        upload_version_content_tool.mode = "content"
        upload_version_content_tool.file = content_package
        upload_version_content_tool.wait_for_job = false

        upload_version_content_tool.execute
        @processing_job_guid = upload_version_content_tool.processing_job_guid
      end
    end

    def upload_version_diff
      Dir.mktmpdir do |temp_dir|
        previous_version_id = draft_version_id - 1

        signatures_package = "#{temp_dir}/#{@secret}_signatures_#{previous_version_id}.zi_"

        download_version_signatures_tool = PatchKitTools::DownloadVersionSignaturesTool.new
        download_version_signatures_tool.secret = @secret
        download_version_signatures_tool.api_key = @api_key
        download_version_signatures_tool.version = previous_version_id
        download_version_signatures_tool.output = signatures_package

        download_version_signatures_tool.execute

        diff_package = "#{temp_dir}/#{@secret}_diff_#{previous_version_id}.zi_"
        diff_summary = "#{temp_dir}/#{@secret}_diff_summary_#{previous_version_id}.txt"

        diff_version_tool = PatchKitTools::DiffVersionTool.new
        diff_version_tool.signatures = signatures_package
        diff_version_tool.files = @files
        diff_version_tool.diff = diff_package
        diff_version_tool.diff_summary = diff_summary

        diff_version_tool.execute

        upload_version_content_tool = PatchKitTools::UploadVersionTool.new
        upload_version_content_tool.secret = @secret
        upload_version_content_tool.api_key = @api_key
        upload_version_content_tool.version = draft_version_id
        upload_version_content_tool.mode = "diff"
        upload_version_content_tool.file = diff_package
        upload_version_content_tool.diff_summary = diff_summary
        upload_version_content_tool.wait_for_job = false

        upload_version_content_tool.execute
        @processing_job_guid = upload_version_content_tool.processing_job_guid
      end
    end

    def app
      @app ||= App.find_by_secret!(@secret)
    end

    def publish_version!
      draft_version.publish_when_processed = true
      draft_version.save!
    end

    def draft_version
      @draft_version ||= app.versions.find(&:draft?)
    end

    def draft_version=(v)
      @draft_version = v
    end

    def draft_version_id
      draft_version.id
    end

    def validate_processed!
      draft_version.reload

      if draft_version.has_processing_error?
        raise_error "Version processing finished with processing error. "\
                                "Please contact support at contact@patchkit.net."
      end

      errors = (draft_version.processing_messages || [])
               .select { |m| m[:severity] == 'error' }
               .map { |m| m[:message] }
      unless errors.empty?
        raise_error "Version processing failed:\n- #{errors.join("\n -")}"
      end
    end

    def import_version!(params)
      app_secret = params.delete(:app_secret) || raise(':app_secret required')
      vid = params.delete(:vid) || raise(':vid required')

      result = draft_version.import!(source_app_secret: app_secret, source_vid: vid)
      @processing_job_guid = result[:job_guid]
    end

    def interactive?
      !@import_app_secret
    end

    def interactive_ask
      ask_if_option_missing!("secret")
      ask_if_option_missing!("api_key")
      ask_if_option_missing!("label")
      ask_if_option_missing!("files")
    end

    def validate_input!
      if mode_files?
        check_option_version_files_directory("files")

        # fix the path slashes
        @files.tr!('\\', '/')
        raise_error "Given directory #{@files} is empty" if Dir["#{@files}/*"].empty?
      elsif mode_import?
        if @import_copy_label && !@label.nil?
          raise_error "--label not allowed if --import-copy-label is set"
        end

        if @import_copy_changelog && !@changelog.nil?
          raise_error "--changelog not allowed when --import-copy-changelog is set"
        end

        if @import_copy_changelog && !@changelog_file.nil?
          raise_error "--changelog not allowed when --import-copy-changelog is set"
        end
      end
    end

    def mode_files?
      !@files.nil?
    end

    def mode_import?
      !mode_files?
    end

    def upload_files!
      if draft_version_id == 1
        puts "There's no previous version. All of the files content will be uploaded"
        upload_version_content
      else
        upload_version_diff
      end
    end
  end
end

if $0 == __FILE__
  PatchKitTools.execute_tool PatchKitTools::MakeVersionTool.new
end

# TODO: check if passed import of -f