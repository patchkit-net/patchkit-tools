#!/usr/bin/env ruby

=begin
$META_START$
name: make-version
summary: Builds, uploads and optionally publshes a new version.
basic: true
class: PatchKitTools::MakeVersionTool
$META_END$
=end

require_relative 'lib/patchkit_tools.rb'
require_relative 'content_version.rb'
require_relative 'create_version.rb'
require_relative 'diff_version.rb'
require_relative 'download_version_signatures.rb'
require_relative 'list_versions.rb'
require_relative 'publish_version.rb'
require_relative 'update_version.rb'
require_relative 'upload_version.rb'

module PatchKitTools
  class MakeVersionTool < PatchKitTools::Tool
    def initialize
      super("make-version", "Creates and uploads a complete version with optional publishing.",
            "[-s <secret>] [-a <api_key>] [-l <label>] [-f <files>] [-c <changelog>]")
    end

    def parse_options
      super do |opts|
        opts.separator "Mandatory"

        opts.on("-s", "--secret <secret>",
          "application secret") do |secret|
          self.secret = secret
        end

        opts.on("-a", "--apikey <api_key>",
          "user API key") do |api_key|
          self.api_key = api_key
        end

        opts.on("-l", "--label <label>",
          "version label") do |label|
          self.label = label
        end

        opts.on("-f", "--files <files>",
          "version files") do |files|
          self.files = files
        end

        opts.separator ""

        opts.separator "Optional"

        opts.on("-p", "--publish <true | false>",
          "should version be published after upload (default: #{self.publish})") do |publish|
          self.publish = publish
        end

        opts.on("-c", "--changelog <changelog>",
          "version changelog") do |changelog|
          self.changelog = changelog
        end

        opts.on("-z", "--changelogfile <changelog_file>",
          "text file with version changelog") do |changelog_file|
          self.changelog_file = changelog_file
        end
      end
    end

    def get_versions_list
      list_versions_tool = PatchKitTools::ListVersionsTool.new
      list_versions_tool.secret = self.secret
      list_versions_tool.api_key = self.api_key
      list_versions_tool.display_limit = 0
      list_versions_tool.sort_mode = "desc"

      list_versions_tool.execute

      list_versions_tool.versions_list
    end

    def update_draft_version(draft_version_id)
      update_version_tool = PatchKitTools::UpdateVersionTool.new
      update_version_tool.secret = self.secret
      update_version_tool.api_key = self.api_key
      update_version_tool.label = self.label
      update_version_tool.changelog = self.changelog unless self.changelog.nil? || self.changelog.empty?
      update_version_tool.changelog_file = self.changelog_file unless self.changelog_file.nil? || self.changelog_file.empty?
      update_version_tool.version = draft_version_id

      update_version_tool.execute
    end

    def create_draft_version
      create_version_tool = PatchKitTools::CreateVersionTool.new
      create_version_tool.secret = self.secret
      create_version_tool.api_key = self.api_key
      create_version_tool.label = self.label
      create_version_tool.execute

      create_version_tool.created_version_id
    end

    def upload_version_content(draft_version_id)
      content_package = "#{self.secret}_content_#{draft_version_id}.zip"

      content_version_tool = PatchKitTools::ContentVersionTool.new
      content_version_tool.files = self.files
      content_version_tool.content = content_package

      begin
        content_version_tool.execute

        upload_version_content_tool = PatchKitTools::UploadVersionTool.new
        upload_version_content_tool.secret = self.secret
        upload_version_content_tool.api_key = self.api_key
        upload_version_content_tool.version = draft_version_id
        upload_version_content_tool.mode = "content"
        upload_version_content_tool.file = content_package

        upload_version_content_tool.execute
      ensure
        FileUtils.rm_rf(content_package)
      end
    end

    def upload_version_diff(draft_version_id)
      previous_version_id = draft_version_id - 1

      signatures_package = "#{self.secret}_signatures_#{previous_version_id}.zip"

      download_version_signatures_tool = PatchKitTools::DownloadVersionSignaturesTool.new
      download_version_signatures_tool.secret = self.secret
      download_version_signatures_tool.api_key = self.api_key
      download_version_signatures_tool.version = previous_version_id
      download_version_signatures_tool.output = signatures_package

      begin
        download_version_signatures_tool.execute

        diff_package = "#{self.secret}_diff_#{previous_version_id}.zip"
        diff_summary = "#{self.secret}_diff_summary_#{previous_version_id}.txt"

        diff_version_tool = PatchKitTools::DiffVersionTool.new
        diff_version_tool.signatures = signatures_package
        diff_version_tool.files = self.files
        diff_version_tool.diff = diff_package
        diff_version_tool.diff_summary = diff_summary

        begin
          diff_version_tool.execute

          upload_version_content_tool = PatchKitTools::UploadVersionTool.new
          upload_version_content_tool.secret = self.secret
          upload_version_content_tool.api_key = self.api_key
          upload_version_content_tool.version = draft_version_id
          upload_version_content_tool.mode = "diff"
          upload_version_content_tool.file = diff_package
          upload_version_content_tool.diff_summary = diff_summary

          upload_version_content_tool.execute
        ensure
          FileUtils.rm_rf(diff_package)
          FileUtils.rm_rf(diff_summary)
        end
      ensure
        FileUtils.rm_rf(signatures_package)
      end
    end

    def publish_version(draft_version_id)
      publish_version_tool = PatchKitTools::PublishVersionTool.new
      publish_version_tool.secret = self.secret
      publish_version_tool.api_key = self.api_key
      publish_version_tool.version = draft_version_id

      publish_version_tool.execute
    end

    def execute
      ask_if_option_missing!("secret")
      ask_if_option_missing!("api_key")
      ask_if_option_missing!("label")
      ask_if_option_missing!("files")
      check_option_version_files_directory("files")

      if Dir["#{self.files}/*"].empty?
        raise CommandLineError, "Given directory #{self.files} is empty"
      end

      versions_list = get_versions_list

      draft_version_id = nil

      if(versions_list.length != 0 && versions_list[0]["draft"])
        draft_version_id = versions_list[0]["id"]

        if(!ask_yes_or_no("Draft version already exists. Its contents will be overwritten. Proceed?", "y"))
          exit
        end
      else
        draft_version_id = create_draft_version
      end

      update_draft_version(draft_version_id)

      if(draft_version_id == 1)
        puts "There's no previous version. All of the files content will be uploaded"

        upload_version_content(draft_version_id)
      else
        upload_version_diff(draft_version_id)
      end

      if(self.publish.nil?)
        if(ask_yes_or_no("Do you want to publish the version?", "y"))
          self.publish = "true"
        end
      end

      if(self.publish == "true")
        publish_version(draft_version_id)
      end
    end
  end
end

if $0 == __FILE__
  PatchKitTools::execute_tool PatchKitTools::MakeVersionTool.new
end
