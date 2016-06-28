#!/usr/bin/env ruby

require 'net/http'

module PatchKitTools
	@@apiUrl = "http://api.patchkit.net"
	def self.api_get(resourcePath)
		return Net::HTTP.get_response(URI("#{@@apiUrl}/#{resourcePath}"));
	end

	def self.api_post(resourcePath, params)
		return Net::HTTP.post_form(URI("#{@@apiUrl}/#{resourcePath}"), params)
	end
end

if __FILE__ == $0
	response = PatchKitTools.api_get("1/apps/e3532b2e6cfe9fee85bee7f05a61bcbc/versions/latest")
	puts response.code
	puts response.body
end