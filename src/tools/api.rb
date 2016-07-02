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

  def self.get_resource_response(resource_name, resource_form = nil, resource_method = Net::HTTP::Get)
		url = get_resource_uri(resource_name)

		Net::HTTP.start(url.host, url.port) do |http|
			request = resource_method.new(url)
      request.set_form(resource_form) if not resource_form.nil?

			http.request(request) do |response|
        if response.kind_of?(Net::HTTPSuccess)
          if block_given?
            yield response
          else
            response
          end
        else
          raise "[#{response.code}] #{response.msg}"
        end
      end
    end
  end

	def self.get_resource_body(resource_name, resource_form = nil, resource_method = Net::HTTP::Get)
		return get_resource_response(resource_name, resource_form).body
	end

	def self.get_resource_object(resource_name, resource_form = nil, resource_method = Net::HTTP::Get)
		return JSON.parse(get_resource_body(resource_name, resource_form))
	end
end
