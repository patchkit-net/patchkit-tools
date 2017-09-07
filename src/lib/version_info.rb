require 'net/http'
require 'json'

require_relative 'version'

module PatchKitTools
  class VersionInfo
    attr_reader :latest
    attr_reader :min_supported

    def self.fetch(timeout = 5)
      uri = URI('https://versions.patchkit.net/patchkit-tools')
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, read_timeout: timeout) do |http|
        request = Net::HTTP::Get.new(uri)
        http.request(request)
      end

      if response.code == '200'
        json = JSON.parse(response.body, symbolize_names: true)
        raise "missing :current key" unless json.include?(:current)
        raise "missing :min_supported key" unless json.include?(:min_supported)

        VersionInfo.new(json[:current], json[:min_supported])
      else
        raise "Cannot retreive version info: #{response}"
      end
    end

    def initialize(latest, min_supported)
      @latest, @min_supported = latest, min_supported
    end

    def latest?
      Gem::Version.new(PatchKitTools::VERSION) >= Gem::Version.new(@latest)
    end

    def min_supported?
      Gem::Version.new(PatchKitTools::VERSION) >= Gem::Version.new(@min_supported)
    end
  end
end
