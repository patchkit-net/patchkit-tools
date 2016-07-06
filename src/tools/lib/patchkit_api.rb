require 'rubygems'
require 'bundler/setup'
require 'net/http'
require 'json'
require_relative 'progress_bar.rb'

# Helper functions for accessing API
module PatchKitAPI
  # Base API url
  API_URL = "http://api.patchkit.net"

  # Returns URI for specified resource
  def self.get_resource_uri(resource_name)
    return URI.parse("#{API_URL}/#{resource_name}")
  end

  # Request for PatchKit API resource
  class ResourceRequest
    attr_reader :http_request

    def initialize(resource_name, resource_form = nil, resource_method = Net::HTTP::Get)
      # Get URI for resource
      @url = PatchKitAPI.get_resource_uri(resource_name)
      # Create request
      @http_request = resource_method.new(@url)
      # Set request form if form argument was passed
      @http_request.set_form(resource_form, "multipart/form-data") if not resource_form.nil?
    end

    # Get response
    def get_response
      Net::HTTP.start(@url.host, @url.port) do |http|
        # Request a response
        http.request(@http_request) do |response|
          # Check if response is correct
          if response.kind_of?(Net::HTTPSuccess)
            yield response if block_given?
          else
            # Raise exception when response was incorrect
            raise "[#{response.code}] #{response.msg}"
          end
        end
      end
    end

    # Get response body
    def get_body
      body = nil
      # Get response
      get_response do |response|
        # Read body from response
        body = response.body
        yield body if block_given?
      end
      return body
    end

    # Get response object (parsed from JSON)
    def get_object
      object = nil
      # Get response body
      get_body do |body|
        # Parse JSON to object
        object = JSON.parse(body)
        yield object if block_given?
      end
      return object
    end
  end

  # Displays proress of background job
  def self.display_job_progress(job_guid)
    # Create new progress bar
    progress_bar = ProgressBar.new(1.0)

    # Frequency of refreshing progress bar (in seconds)
    refresh_frequency = 1

    loop do
      # Save the start time of refreshing
      start_time = Time.now

      # Fetch background job status
      job_status = PatchKitAPI::ResourceRequest.new("1/background_jobs/#{job_guid}").get_object

      # Prepare status message
      status_message = job_status["status_message"]
      status_message = "Pending" if job_status["pending"]
      status_message = "Finished!" if job_status["finished"]

      # Display progress bar with status message
      progress_bar.print(job_status["progress"], status_message)

      # If job has finished we can exit the loop
      if(job_status["finished"])
        break
      end

      # Sleep to keep frequency of refreshing
      sleep [[Time.now - start_time, 0].max, refresh_frequency].min
    end
  end
end
