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

      def self.create(app, params)
        path = AbstractModel.construct_path("1/apps/#{app.secret}/versions")
        data = PatchKitAPI.post(path, params: params)
        Version.new(app, data)
      end

      def self.find_by_id!(app, id)
        path = AbstractModel.construct_path("1/apps/#{app.secret}/versions/#{id}")
        Version.new(app, PatchKitAPI.get(path))
      end

      def import!(params)
        do_post("1/apps/#{app.secret}/versions/#{id}/import", params)
      end

      def upload_content!(params)
        do_put("1/apps/#{app.secret}/versions/#{id}/content_file", params)
      end

      def upload_diff!(params)
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
