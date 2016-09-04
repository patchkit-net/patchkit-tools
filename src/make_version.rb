#!/usr/bin/env ruby

require_relative 'lib/patchkit_api.rb'
require_relative 'lib/patchkit_tools.rb'
require_relative 'lib/zip_helper.rb'
require_relative 'lib/file_helper.rb'
require_relative 'list_versions.rb'
require_relative 'create_version.rb'
require_relative 'update_version.rb'
require_relative 'download_version_signatures.rb'
require_relative 'upload_version.rb'
require_relative 'publish_version.rb'

module PatchKitTools
  class MakeVersionTool < PatchKitTools::Tool
    def initialize
      super("make-version", "Creates a version, generates a diff (if it's possible), uploads it and publishes.",
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
          "should version be published after upload") do |publish|
          self.publish = publish
        end

        opts.on("-c", "--changelog <changelog>",
          "version changelog") do |changelog|
          self.changelog = changelog
        end
      end
    end

    def execute
      ask_if_option_missing!("secret")
      ask_if_option_missing!("api_key")
      ask_if_option_missing!("label")
      ask_if_option_missing!("files")
      check_if_option_directory_exists("files")

      list_versions_tool = PatchKitTools::ListVersionsTool.new
      list_versions_tool.secret = self.secret
      list_versions_tool.api_key = self.api_key
      list_versions_tool.display_mode = "raw"

      list_versions_tool.execute

      draft_version_id = nil

      if(list_versions_tool.versions_list.length != 0 && list_versions_tool[0]["draft"])
        if(!ask_yes_or_no("Draft version is already created. It will be used for making new version. Do you want to proceed?"))
          exit
        end

        draft_version_id = list_versions_tool[0]["id"]

        update_version_tool = PatchKitTools::UpdateVersionTool.new
        update_version_tool.secret = self.secret
        update_version_tool.api_key = self.api_key
        update_version_tool.label = self.label
        update_version_tool.version = self.draft_version_id

        update_version_tool.execute
      else
        create_version_tool = PatchKitTools::CreateVersionTool.new
        create_version_tool.secret = self.secret
        create_version_tool.api_key = self.api_key
        create_version_tool.label = self.label
        puts create_version_tool
        create_version_tool.execute
        puts "elo"
        draft_version_id = create_version_tool.created_version_id
      end

      if(draft_version_id == 0)
        if(!ask_yes_or_no("There's no previous version. All of the files content will be uploaded. Do you want to proceed?"))
          exit
        end

        content_package = "#{self.secret}_content_#{draft_version_id}.zip"

        content_hash = {}

        FileHelper::list_relative(self.files) do |file|
          content_hash[File.join(self.files, file)] = file
        end

        begin
          ZipHelper::zip(content_hash, content_package)

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
      else
        previous_version_id = draft_version_id - 1

        signatures_package = "#{self.secret}_signatures_#{previous_version_id}.zip"

        download_version_signatures_tool = PatchKitTools::DownloadVersionSignaturesTool.new
        download_version_signatures_tool.secret = self.secret
        download_version_signatures_tool.api_key = self.api_key
        download_version_signatures_tool.version = previous_version_id
        download_version_signatures_tool.output = signatures

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

      if(self.publish)
        publish_version_tool = PatchKitTools::PublishVersionTool.new
        publish_version_tool.secret = self.secret
        publish_version_tool.api_key = self.api_key
        publish_version_tool.version = draft_version_id

        publish_version_tool.execute
      end
    end
  end
end

if $0 == __FILE__
  PatchKitTools::execute_tool PatchKitTools::MakeVersionTool.new
end
