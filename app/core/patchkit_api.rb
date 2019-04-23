require 'net/http'
require 'json'

require_relative 'utils/progress_bar'
require_relative 'patchkit_config'
require_relative 'patchkit_error'

module PatchKitAPI
  class << self
    attr_accessor :api_url
    attr_accessor :api_key

    # deprecated since 10.04.2017
    def get_resource_uri(resource_name)
      resource_uri(resource_name)
    end

    def resource_uri(path)
      api_url = defined?(@api_url) ? @api_url : PatchKitConfig.api_url
      if path.start_with? '/'
        URI.parse("#{api_url}#{path}")
      else
        URI.parse("#{api_url}/#{path}")
      end
    end

    def get(path, **params)
      req = PatchKitAPI::ResourceRequest.new(path, Net::HTTP::Get)
      process_request(req, params)
    end

    def post(path, **params)
      req = PatchKitAPI::ResourceRequest.new(path, Net::HTTP::Post)
      process_request(req, params)
    end

    def patch(path, params)
      req = PatchKitAPI::ResourceRequest.new(path, Net::HTTP::Patch)
      process_request(req, params)
    end

    def put(path, params)
      req = PatchKitAPI::ResourceRequest.new(path, Net::HTTP::Put)
      process_request(req, params)
    end

    def process_request(request, params)
      request.form = params.delete(:params).collect{ |k, v| [k.to_s, v.to_s]}.to_h if params.include? :params
      request.headers = params.delete(:headers).collect{ |k, v| [k.to_s, v.to_s]}.to_h if params.include? :headers

      raise "unknown keys: #{params.keys}" unless params.empty?

      response = request.get_response
      JSON.parse(response.body, symbolize_names: true)
    end
  end

  class ResourceRequest
    attr_reader :http_request
    attr_accessor :headers
    attr_accessor :form
    attr_accessor :offset

    def initialize(resource_name, resource_method = Net::HTTP::Get)
      @url = PatchKitAPI.resource_uri(resource_name)
      @resource_method = resource_method
      @headers = {}
      @form = {}
      @offset = 0
    end

    def get_response
      http_request = @resource_method.new(@url)
      http_request.set_form(@form, "multipart/form-data") unless @form.nil? || @form.empty?
      if http_request['Range'].nil? && offset > 0
        http_request['Range'] = "bytes=#{offset}-"
      end

      @headers.each { |key, value| http_request[key] = value }

      Net::HTTP.start(@url.host, @url.port, use_ssl: @url.scheme == 'https') do |http|
        http.request(http_request) do |response|
          if response.kind_of?(Net::HTTPSuccess)
            yield response if block_given?
          else
            raise PatchKitTools::APIError,
                  "[#{response.code}] #{response.msg} while requesting #{@url}: #{response.body}"
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
        progress_bar.print(last_progress, "WARNING: Cannot read job status. Will try again...", force: true)
      end

      request_time = Time.now - start_time
      remaining_time = refresh_frequency - request_time
      sleep [remaining_time, 0].max
    end

    unless last_status.zero?
      raise APIJobError, "#{last_status_message}. Please visit panel.patchkit.net for more information."
    end

    progress_bar.print(last_progress, last_status_message, force: true)
  end

  def self.wait_until_version_published(secret, version_id)
    progress_bar = ProgressBar.new(1.0)

    refresh_frequency = 1

    last_progress = 0
    last_published = false

    loop do
      start_time = Time.now

      begin
        job_status = PatchKitAPI.get("1/apps/#{secret}/versions/#{version_id}")

        last_progress = job_status[:publish_progress]
        last_published = job_status[:published]

        break if job_status[:published]
        break unless job_status[:pending_publish]

        progress_bar.print(last_progress, "Publishing...")
      rescue
        progress_bar.print(last_progress, "WARNING: Cannot read publishing status. Will try again...")
      end

      request_time = Time.now - start_time
      remaining_time = refresh_frequency - request_time
      sleep [remaining_time, 0].max
    end

    unless last_published
      raise APIPublishError, "Unable to publish version. Please visit panel.patchkit.net for more information."
    end

    progress_bar.print(last_progress, "Version has been published!", force: true)
  end
end
