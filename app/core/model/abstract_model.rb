require_relative '../patchkit_api'

module PatchKitTools
  module Model
    class AbstractModel
      def initialize(path)
        @path = path
        @dirty = []
      end

      def self.construct_path(path)
        if PatchKitAPI.api_key.nil?
          path
        else
          path + "?api_key=#{PatchKitAPI.api_key}"
        end
      end

      def do_get(path)
        PatchKitAPI.get(construct_path(path))
      end

      def do_post(path, params)
        PatchKitAPI.post(construct_path(path), params: params)
      end

      def do_put(path, params)
        PatchKitAPI.put(construct_path(path), params: params)
      end

      def save!
        PatchKitAPI.patch(construct_path(@path), params: dirty_params)
        @dirty = []
      end

      def reload
        @data = PatchKitAPI.get(construct_path(@path))
      end

      def method_missing(m, *args, &block)
        sanitized = sanitize_name(m)
        if @data.include? sanitized
          if getter? m
            @data[sanitized]
          elsif setter? m
            if @data[sanitized] != args[0]
              @data[sanitized] = args[0]
              @dirty << sanitized
            end
          end
        else
          super
        end
      end

      def respond_to_missing?(m, include_private = false)
        sanitized = sanitize_name(m)
        if @data.include? sanitized
          true
        else
          super
        end
      end

      private

        def construct_path(path)
          AbstractModel.construct_path(path)
        end

        def dirty_params
          h = {}
          @dirty.each { |key| h[key] = @data[key] }
          h
        end

        def setter?(name)
          name.to_s.end_with? '='
        end

        def getter?(name)
          !setter?(name)
        end

        def sanitize_name(name)
          if name.to_s.end_with?('?', '=')
            name[0..-2].to_sym
          else
            name
          end
        end
    end
  end
end
