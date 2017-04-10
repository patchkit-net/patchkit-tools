require 'net/http'
require 'json'
require 'rest-client'
require_relative 'progress_bar.rb'
require_relative 'patchkit_config.rb'

module PatchKitAPI
  class << self
    attr_accessor :api_url

    # deprecated since 10.04.2017
    def get_resource_uri(resource_name)
      resource_uri(resource_name)
    end

    def resource_uri(path)
      api_url = @api_url || PatchKitConfig.api_url
      URI.parse("#{api_url}/#{path}")
    end

    # Preferred method of doing get calls
    def get(path, **params)
      uri = PatchKitAPI.resource_uri(path).to_s
      r = RestClient.get uri, params: params
      JSON.parse(r.body, symbolize_names: true)
    end
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

    last_status_message = ""

    last_status = 0

    loop do
      start_time = Time.now

      begin
        job_status = PatchKitAPI.get("1/background_jobs/#{job_guid}")

        last_progress = job_status[:progress]
        last_status = job_status[:status]

        status_message = job_status[:status_message]
        
        if last_status.zero?
          status_message = "Pending" if job_status[:pending]
          status_message = "Done" if job_status[:finished]
        end

        last_status_message = status_message

        progress_bar.print(last_progress, last_status_message)

        break if job_status[:finished]
      rescue
        progress_bar.print(last_progress, "WARNING: Cannot read job status. Will try again...")
      end

      sleep [[Time.now - start_time, 0].max, refresh_frequency].min
    end

    unless last_status.zero?
      raise APIJobError, "#{last_status_message}. Please visit panel.patchkit.net for more information."
    end

    progress_bar.print(last_progress, last_status_message)
  end
end
