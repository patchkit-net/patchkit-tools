require 'tempfile'

require_relative 'test_helper'
require_relative '../app/download_version_signatures.rb'

include PatchKitTools::Model

class DownloadVersionSignaturesTest < Test::Unit::TestCase
  def setup
    WebMock.reset!
    PatchKitTools::Printer.quiet = true
    ProgressBar.any_instance.stubs(:print)

    @tempfile = Tempfile.new
    @args = "-a api_key -s secret -v 1 -o #{@tempfile.path}".split(' ')
  end

  def teardown
    @tempfile.close!
  end

  def test_download
    stub_request(:get, "http://api.patchkit.net/1/apps/secret?api_key=api_key").
      to_return(status: 200, body: {secret: 'secret'}.to_json, headers: {})

    stub_request(:get, "http://api.patchkit.net/1/apps/secret/versions/1?api_key=api_key").
      to_return(status: 200, body: {id: 1}.to_json, headers: {})

    stub_request(:get, "http://api.patchkit.net/1/apps/secret/versions/1/signatures?api_key=api_key").
      to_return(status: 200, body: "abc123", headers: { 'Content-Length' => 6})

    tool = PatchKitTools::DownloadVersionSignaturesTool.new(@args)
    tool.parse_options
    tool.execute

    assert_equal 'abc123', File.read(@tempfile)
  end

  def test_download_connection_broken
    stub_request(:get, "http://api.patchkit.net/1/apps/secret?api_key=api_key").
      to_return(status: 200, body: {secret: 'secret'}.to_json, headers: {})

    stub_request(:get, "http://api.patchkit.net/1/apps/secret/versions/1?api_key=api_key").
      to_return(status: 200, body: {id: 1}.to_json, headers: {})

    stub_request(:get, "http://api.patchkit.net/1/apps/secret/versions/1/signatures?api_key=api_key").
      to_return(status: 200, body: "abc", headers: { 'Content-Length' => 6 })

    stub_request(:get, "http://api.patchkit.net/1/apps/secret/versions/1/signatures?api_key=api_key").
      with(
        headers: {
          'Range' => 'bytes=3-'
        }
      ).
      to_return(status: 200, body: "321", headers: { 'Content-Length' => 6 })

    tool = PatchKitTools::DownloadVersionSignaturesTool.new(@args)
    tool.parse_options
    tool.execute

    assert_equal 'abc321', File.read(@tempfile)
  end
end