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

      def download_signatures
        path = construct_path("1/apps/#{app.secret}/versions/#{id}/signatures")
        request = PatchKitAPI::ResourceRequest.new(path)
        request.get_response { |r| yield r }
      end
    end
  end
end
