require_relative 'test_helper'
require_relative '../app/core/version_info'

class ChangelogTest < Test::Unit::TestCase
  def test_latest
    mock_response('{"current":"' + PatchKitTools::VERSION + '","min_supported":"1.1.0"}')
    version_info = PatchKitTools::VersionInfo.fetch

    assert version_info.latest?
    assert version_info.min_supported?

    # this version is lower than current
    mock_response('{"current":"1.1.9","min_supported":"1.1.0"}')
    version_info = PatchKitTools::VersionInfo.fetch

    assert version_info.latest?
    assert version_info.min_supported?
  end

  def test_not_latest
    mock_response('{"current":"123.0.0","min_supported":"1.2.0"}')
    version_info = PatchKitTools::VersionInfo.fetch

    refute version_info.latest?
    assert version_info.min_supported?
  end

  def test_min_supported
    mock_response('{"current":"123.0.0","min_supported":"' + PatchKitTools::VERSION + '"}')
    version_info = PatchKitTools::VersionInfo.fetch

    assert version_info.min_supported?

    mock_response('{"current":"123.0.0","min_supported":"123.0.0"}')
    version_info = PatchKitTools::VersionInfo.fetch

    refute version_info.min_supported?
  end

  private

    def mock_response(text)
      http = mock('http')
      response = mock('response')

      Net::HTTP.expects(:start)
               .with("versions.patchkit.net", 443, use_ssl: true, read_timeout: 5)
               .yields(http)
               .returns(response)

      get = mock('get')
      Net::HTTP::Get.expects(:new).returns(get)
      
      http.expects(:request).with(get).returns(response)

      response.expects(:code).returns('200')
      response.expects(:body)
              .returns(text)
    end
end
