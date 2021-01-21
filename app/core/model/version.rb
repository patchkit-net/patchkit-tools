require 'uri'

require_relative 'abstract_model'

module PatchKitTools
  module Model
    class Version < AbstractModel
      attr_reader :app

      def initialize(app, data)
        @app = app
        @data = data

        super "1/apps/#{app.secret}/versions/#{id}"
      end

      def self.create(app, **params)
        path = AbstractModel.construct_path("1/apps/#{app.secret}/versions")
        data = PatchKitAPI.post(path, params: params)
        Version.new(app, data)
      end

      def self.find_by_id!(app, id)
        path = AbstractModel.construct_path("1/apps/#{app.secret}/versions/#{id}")
        Version.new(app, PatchKitAPI.get(path))
      end

      def import!(params)
        raise ":source_app_secret required" unless params.include? :source_app_secret
        raise ":source_vid required" unless params.include? :source_vid

        do_post("1/apps/#{app.secret}/versions/#{id}/import", params)
      end

      def link_to!(source_app_secret:, source_vid:)
        do_post("1/apps/#{app.secret}/versions/#{id}/link",
                source_app_secret: source_app_secret, source_app_version_id: source_vid)
      end

      def upload_content!(params)
        raise ":upload_id required" unless params.include? :upload_id

        do_put("1/apps/#{app.secret}/versions/#{id}/content_file", params)
      end

      def upload_diff!(params)
        raise ":upload_id required" unless params.include? :upload_id
        raise ":diff_summary required" unless params.include? :diff_summary

        do_put("1/apps/#{app.secret}/versions/#{id}/diff_file", params)
      end

      def download_signatures(offset: 0, &block)
        path = construct_path("1/apps/#{app.secret}/versions/#{id}/signatures/url")
        resp = PatchKitAPI.get(path)
        url = resp[:url]
        size = resp[:size]

        if size.zero?
          puts "Cannot download signatures using CDN, falling back to slow direct download"
          return download_signatures_fallback(offset: 0, &block)
        end

        part_size = 1024**2 * 512
        parts = size / part_size
        parts += 1 if size % part_size != 0

        parts.times do |part|
          url = "#{url}.#{part}" unless part.zero?
          uri = URI(url)

          part_start = part * part_size
          part_end = (part + 1) * part_size - 1

          if offset <= part_end
            part_offset = [offset - part_start, 0].max

            Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
              request = Net::HTTP::Get.new uri
              request['Range'] = "bytes=#{part_offset}-" if part_offset > 0

              http.request request do |response|
                yield response, size
              end
            end
          end
        end
      end

      def download_signatures_fallback(offset: 0)
        path = construct_path("1/apps/#{app.secret}/versions/#{id}/signatures")
        request = PatchKitAPI::ResourceRequest.new(path)
        request.offset = offset
        request.get_response { |r| yield r }
      end
    end
  end
end
