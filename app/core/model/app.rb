require_relative 'abstract_model'
require_relative 'version'

module PatchKitTools
  module Model
    class App < AbstractModel
      def initialize(data)
        @data = data
        super "1/apps/#{secret}"
      end

      def self.all
        apps = do_get("1/apps")
        apps.map { |a| App.new(a) }
      end

      def self.find_by_secret!(secret)
        App.new(PatchKitAPI.get(AbstractModel.construct_path("1/apps/#{secret}")))
      end

      def versions
        versions = do_get("1/apps/#{secret}/versions")
        versions.map { |v| Version.new(self, v) }
      end

      def published_versions
        versions = do_get("1/apps/#{secret}/versions")
        versions = versions.select { |v| v[:published] }
        versions.map { |v| Version.new(self, v) }
      end

      def group
        App.find_by_secret!(parent_group[:secret])
      end
    end
  end
end
