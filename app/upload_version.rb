#!/usr/bin/env ruby

=begin
$META_START$
name: upload-version
summary: Uploads new version by sending content or diff file.
basic: false
class: PatchKitTools::UploadVersionTool
$META_END$
=end

require_relative 'core/patchkit_api.rb'
require_relative 'core/patchkit_tools.rb'
require 'rubygems'
require 'bundler/setup'
require 'net/http/uploadprogress'
require 'digest'

module PatchKitTools
  # after successful upload, you can read the result job GUID here
  attr_reader :processing_job_guid

  class UploadVersionTool < PatchKitTools::BaseTool
    UPLOAD_MODES = ["content", "diff"]

    def initialize
      super("upload-version", "Uploads new version by sending content or diff.",
            "-m content -s <secret> -a <api_key> -v <version> -f <file> [optional]",
            "-m diff -s <secret> -a <api_key> -v <version> -f <file> -d <diff_summary> [optional]")

      self.wait_for_job = true
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

        opts.on("-v", "--version <version>", Integer,
          "application version") do |version|
          self.version = version
        end

        opts.on("-m", "--mode <mode>",
          "upload mode; #{UPLOAD_MODES.join(", ")}") do |mode|
          self.mode = mode
        end

        opts.on("-f", "--file <file>",
          "file to upload") do |file|
          self.file = file
        end

        opts.on("-d", "--diffsummary <diff_summary>",
          "file with diff summary (required only when --mode=diff)") do |diff_summary|
            self.diff_summary = diff_summary
        end

        opts.separator ""

        opts.separator "Optional"

        opts.on("-w", "--waitforjob <true | false>",
          "should program wait for finish of version processing job (default: #{self.wait_for_job})") do |wait_for_job|
            self.wait_for_job = wait_for_job
          end
      end
    end

    def upload(&block)
      begin
        #TODO: Try to replace file_size with file_stream.size and confirm that it's working.
        file_stream = File.open(self.file)
        file_size = File.size(self.file)

        new_upload_resource_name = "1/uploads?api_key=#{self.api_key}"
        new_upload_resource_form =
        {
          "total_size_bytes" => file_size.to_s
        }

        new_upload_resource_request = PatchKitAPI::ResourceRequest.new(
          new_upload_resource_name,
          new_upload_resource_form,
          Net::HTTP::Post
        )

        upload_id = new_upload_resource_request.get_object["id"]

        offset = 0

        until offset == file_size
          begin
            uploaded_chunk_size = upload_chunk(file_stream, file_size, offset, upload_id) do |uploaded_bytes|
              block.call(offset + uploaded_bytes)
            end

            offset = offset + uploaded_chunk_size
          rescue => e
            puts "Failed to upload chunk with offset #{offset}, message: #{e.message}. Retrying..."
            puts
            puts
          end
        end

        upload_id
      ensure
        file_stream.close
      end
    end

    def upload_chunk(file_stream, file_size, offset, upload_id)
      Dir.mktmpdir do |temp_dir|
        chunk_file_name = "#{temp_dir}/chunk_#{offset}"

        # set the file position at current offset
        file_stream.rewind
        file_stream.seek(offset, IO::SEEK_CUR)

        File.open(chunk_file_name, 'wb') do |f|
          f.write file_stream.read(PatchKitConfig.upload_chunk_size)
        end

        File.open(chunk_file_name, 'rb') do |f|
          md5 = Digest::MD5.file(chunk_file_name).hexdigest

          form_data = { "chunk" => f, "md5" => md5 }
          resource_name = "1/uploads/#{upload_id}/chunk?api_key=#{api_key}"
          request = PatchKitAPI::ResourceRequest.new(resource_name, form_data, Net::HTTP::Post)

          request.http_request['Content-Range'] =
            "bytes #{offset}-#{offset + File.size(chunk_file_name) - 1}/#{file_size}"

          Net::HTTP::UploadProgress.new(request.http_request) do |progress|
            yield progress.upload_size
          end

          request.get_response
        end

        File.size(chunk_file_name)
      end
    end

    def execute
      check_if_option_exists("secret")
      check_if_option_exists("api_key")
      check_if_option_exists("version")
      check_if_valid_option_value("mode", UPLOAD_MODES)
      check_if_option_file_exists_and_readable("file")
      check_if_option_file_exists_and_readable("diff_summary") if self.mode == "diff"

      # Check if the version is draft
      puts "Checking version..."
      version_status = (PatchKitAPI::ResourceRequest.new "1/apps/#{self.secret}/versions/#{self.version}?api_key=#{self.api_key}").get_object
      raise "Version must be a draft" unless version_status["draft"]

      puts "Uploading #{self.mode}..."

      file_size = File.size(self.file)

      progress_bar = ProgressBar.new(file_size)

      last_upload_callback_time = 0

      upload_id = upload do |progress|
        current_upload_callback_time = Time.now.to_f
        if current_upload_callback_time - last_upload_callback_time > 0.5
          progress_bar.print(progress, "Uploading %.2f MB out of %.2f MB" % [progress / 1024.0 / 1024.0, file_size / 1024.0 / 1024.0])
          last_upload_callback_time = current_upload_callback_time
        end
      end

      progress_bar.print(file_size, "Upload done")

      update_version_resource_name, update_version_resource_form = case self.mode
      when "content"
        [
          "1/apps/#{self.secret}/versions/#{self.version}/content_file?api_key=#{self.api_key}",
          {
            "upload_id" => upload_id.to_s
          }
        ]
      when "diff"
        [
          "1/apps/#{self.secret}/versions/#{self.version}/diff_file?api_key=#{self.api_key}",
          {
            "upload_id" => upload_id.to_s,
            "diff_summary" => File.open(self.diff_summary, 'rb') { |f| f.read }
          }
        ]
      end

      update_version_resource_request = PatchKitAPI::ResourceRequest.new(update_version_resource_name, update_version_resource_form, Net::HTTP::Put)

      update_version_resource_request.get_object do |object|
        @processing_job_guid = object['job_guid']
        # Optionally wait for finish of version processing job
        if self.wait_for_job
          puts "Waiting for finish of version processing job..."

          # Display job progress bar
          PatchKitAPI.display_job_progress(@processing_job_guid)
        end
      end
    end
  end
end

if $0 == __FILE__
  PatchKitTools::execute_tool PatchKitTools::UploadVersionTool.new
end
