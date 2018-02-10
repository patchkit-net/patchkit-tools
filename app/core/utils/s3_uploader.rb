require 'securerandom'
require_relative 'limited_reader'
require_relative '../patchkit_api'

module PatchKitTools
  class S3Uploader
    attr_accessor :part_size
    attr_reader :upload_id

    def initialize(api_key)
      @api_key = api_key || raise("missing api key")
      @part_size = 1024**2 * 32 # 32 megabytes
      @on_progress = []
    end

    # :progress is called with (bytes_sent, bytes_total)
    def on(action, &block)
      case action
      when :progress
        @on_progress << block
      else
        raise "unknown action: #{action}"
      end
    end

    def upload_file(file)
      @total = File.size(file)
      create_upload_object(@total)

      File.open(file, 'rb') do |f|
        offset = 0
        @on_progress.each { |block| block.call(offset, @total) }

        each_part(f) do |part_io, size|
          part_io.on_read do
            num = offset + (size - part_io.remaining)
            @on_progress.each { |block| block.call(num, @total) }
          end

          upload_part(part_io, offset, size)
          offset += size

          @on_progress.each { |block| block.call(offset, @total) }
        end
      end
    end

    private

      def each_part(io)
        until io.eof?
          pos = io.pos
          part_size = [@part_size, @total - pos].min

          yield LimitedReader.new(io, part_size), part_size
        end
      end

      def create_upload_object(total_size)
        response = PatchKitAPI.post('1/uploads',
                                    params: { api_key: @api_key, storage_type: 's3', total_size_bytes: total_size })
        @upload_id = response[:id]
      end

      def upload_part(io, offset, size)
        uri = generate_s3_uri(offset, size)
        upload_to_s3(uri, io, size)
      end

      def generate_s3_uri(offset, size)
        last_byte = offset + size - 1
        response = PatchKitAPI.post("1/uploads/#{@upload_id}/gen_chunk_url",
                                    params: { api_key: @api_key },
                                    headers: { :'Content-Range' => "bytes #{offset}-#{last_byte}/#{@total}" })
        URI.parse(response[:url])
      end

      def upload_to_s3(uri, io, size)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE

        request = Net::HTTP::Put.new(uri.request_uri)
        request['Content-Type'] = ''
        request['Content-Length'] = size

        # accelerated connection is a direct connection, it requires acl header
        if uri.host.include? 's3-accelerate.amazonaws.com'
          request['x-amz-acl'] = 'bucket-owner-full-control'
        end

        request.body_stream = io

        response = http.request(request)

        return if response.is_a? Net::HTTPSuccess
        raise "[#{response.code}] #{response.msg} while uploading to S3: #{response.body}"
      end
  end
end
