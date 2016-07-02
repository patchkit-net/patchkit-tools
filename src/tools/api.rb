require 'rubygems'
require 'bundler/setup'

require 'net/http'
require 'net/http/uploadprogress'
require 'json'

module PatchKitAPI
  API_URL = "http://api.patchkit.net"

  def self.get_resource_uri(resource_name)
    return URI.parse("#{API_URL}/#{resource_name}")
  end

  def self.get_resource_response(resource_name, resource_form = nil, resource_method = Net::HTTP::Get, prepare_request_lambda = nil)
    url = get_resource_uri(resource_name)

    Net::HTTP.start(url.host, url.port) do |http|
      request = resource_method.new(url)
      request.set_form(resource_form, "multipart/form-data") if not resource_form.nil?

      prepare_request_lambda.call request unless prepare_request_lambda.nil?

      return_value = nil

      http.request(request) do |response|
        if response.kind_of?(Net::HTTPSuccess)
          if block_given?
            return_value = yield response
          else
            return_value = response
          end
        else
          raise "[#{response.code}] #{response.msg}"
        end
      end

      return return_value
    end
  end

  def self.get_resource_body(resource_name, resource_form = nil, resource_method = Net::HTTP::Get, prepare_request_lambda = nil)
    get_resource_response(resource_name, resource_form, resource_method, prepare_request_lambda) do |response|
      if block_given?
        yield response.body
      else
        response.body
      end
    end
  end

  def self.get_resource_object(resource_name, resource_form = nil, resource_method = Net::HTTP::Get, prepare_request_lambda = nil, &block)
    get_resource_body(resource_name, resource_form, resource_method, prepare_request_lambda) do |body|
      if block_given?
        yield JSON.parse(body)
      else
        JSON.parse(body)
      end
    end
  end

  def self.display_job_progress(job_guid)
    loop do
      start_time = Time.now

      puts get_resource_object("1/background_jobs/#{job_guid}")

      sleep [[Time.now - start_time, 0].max, 1].min
    end
  end
end
