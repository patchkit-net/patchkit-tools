require 'net/http'
require 'json'
require_relative 'progress_bar.rb'
require_relative 'patchkit_config.rb'

module PatchKitAPI
  def self.get_resource_uri(resource_name)
    URI.parse("#{PatchKitConfig.api_url}/#{resource_name}")
  end

  class ResourceRequest
    attr_reader :http_request

    def initialize(resource_name, resource_form = nil, resource_method = Net::HTTP::Get)
      @url = PatchKitAPI.get_resource_uri(resource_name)
      @http_request = resource_method.new(@url)
      @http_request.set_form(resource_form, "multipart/form-data") if not resource_form.nil?
    end

    def get_response
      Net::HTTP.start(@url.host, @url.port) do |http|
        http.request(@http_request) do |response|
          if response.kind_of?(Net::HTTPSuccess)
            yield response if block_given?
          else
            raise "[#{response.code}] #{response.msg} while requesting #{@url}"
          end
        end
      end
    end

    def get_body
      body = nil
      get_response do |response|
        body = response.body
        yield body if block_given?
      end
      return body
    end

    def get_object
      object = nil
      get_body do |body|
        object = JSON.parse(body)
        yield object if block_given?
      end
      return object
    end
  end

  def self.display_job_progress(job_guid)
    progress_bar = ProgressBar.new(1.0)

    refresh_frequency = 1

    last_progress = 0

    loop do
      start_time = Time.now

      begin
        job_status = PatchKitAPI::ResourceRequest.new("1/background_jobs/#{job_guid}").get_object

        status_message = job_status["status_message"]
        status_message = "Pending" if job_status["pending"]
        status_message = "Finished!" if job_status["finished"]

        progress_bar.print(job_status["progress"], status_message)

        last_progress = job_status["progress"]

        if(job_status["finished"])
          if(job_status["status"] != 0)
            raise job_status["status_message"]
          end
          break
        end
      rescue
        progress_bar.print(last_progress, "WARNING: Cannot retrieve job status")
      end

      sleep [[Time.now - start_time, 0].max, refresh_frequency].min
    end
  end
end
