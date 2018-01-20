require 'tempfile'

require_relative 'test_helper'
require_relative '../app/core/s3_uploader'

class S3UploaderTest < Test::Unit::TestCase
  def test_upload
    # generate 3 kb file
    file = Tempfile.new('foo')
    file.write("a" * (1024 * 3))
    file.close

    uploader = PatchKitTools::S3Uploader.new('api_key')
    uploader.part_size = 2048

    PatchKitAPI.expects(:post).with('1/uploads', params: { api_key: 'api_key', total_size_bytes: 1024 * 3, storage_type: 's3' })
               .returns({ id: 42 })

    PatchKitAPI.expects(:post)
               .with('1/uploads/42/gen_chunk_url', params: { api_key: 'api_key' }, headers: { :"Content-Range" => "bytes 0-2047/3072" })
               .returns({ url: 'https://s3.url/something' })

    PatchKitAPI.expects(:post)
               .with('1/uploads/42/gen_chunk_url', params: { api_key: 'api_key' }, headers: { :"Content-Range" => "bytes 2048-3071/3072" })
               .returns({ url: 'https://s3.url/something' })

    uploader.expects(:upload_to_s3).with do |uri, io|
      io.read
      true
    end.twice

    uploader.upload_file(file.path)
  end
end
