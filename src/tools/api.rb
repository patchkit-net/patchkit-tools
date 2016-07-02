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

	def self.get_resource_response(resource_name)
		url = get_resource_uri(resource_name)

		Net::HTTP.start(url.host, url.port) do |http|
			request = Net::HTTP::Get.new(url)

			response = http.request(request)

			return response
		end
	end

	def self.get_resource_body(resource_name)
		response = get_resource_response(resource_name)

		if response.kind_of?(Net::HTTPSuccess)
			return response.body
		else
			raise "[#{response.code}] #{response.msg}"
		end
	end

	def self.get_resource_object(resource_name)
		body = get_resource_body(resource_name)

		return JSON.parse(body)
	end
end
