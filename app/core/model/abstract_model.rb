require_relative '../patchkit_api'
require_relative '../utils/retry'

module PatchKitTools
  module Model
    class AbstractModel
      attr_reader :path

      RETRY_ERRORS = [Errno::ECONNRESET, Errno::ECONNABORTED, Errno::EPROTO]
      GET_RETRY_ERRORS = RETRY_ERRORS + [Net::HTTPBadResponse, Net::HTTPBadGateway, Net::HTTPGatewayTimeOut, Net::HTTPServiceUnavailable, Net::HTTPInternalServerError]

      def initialize(path)
        @path = path
        @dirty = []
      end

      def self.construct_path(path)
        path
      end

      def do_get(path)
        Retry.on(*GET_RETRY_ERRORS) { PatchKitAPI.get(construct_path(path)) }
      end

      def do_post(path, params)
        Retry.on(*RETRY_ERRORS) { PatchKitAPI.post(construct_path(path), params: params) }
      end

      def do_put(path, params)
        Retry.on(*RETRY_ERRORS) { PatchKitAPI.put(construct_path(path), params: params) }
      end

      def save!
        Retry.on(*RETRY_ERRORS) { PatchKitAPI.patch(construct_path(@path), params: dirty_params) }
        @dirty = []
      end

      def reload
        @data = PatchKitAPI.get(construct_path(@path))
        self
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
          if PatchKitConfig.debug
            raise NoMethodError, "No method #{m} in #{self.inspect}"
          else
            super
          end
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
