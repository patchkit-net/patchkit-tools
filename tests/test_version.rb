require_relative 'test_helper'
require_relative '../app/core/model/app'

include PatchKitTools::Model

class VersionTest < Test::Unit::TestCase
  def setup
    PatchKitAPI.api_key = 'my_key'

    @app = mock('app')
    @app.stubs(:secret).returns('sec')
  end

  def test_create
    PatchKitAPI.expects(:post).with('1/apps/sec/versions?api_key=my_key', params: {}).returns(id: 1)
    version = Version.create(@app, {})
    assert_equal 1, version.id
  end

  def test_create_with_label
    PatchKitAPI.expects(:post).with('1/apps/sec/versions?api_key=my_key', params: { label: 'a' })
               .returns(id: 1)
    version = Version.create(@app, label: 'a')
    assert_equal 1, version.id
  end

  def test_find_by_id
    PatchKitAPI.expects(:get).with('1/apps/sec/versions/2?api_key=my_key').returns(id: 2)
    version = Version.find_by_id!(@app, 2)
    assert_equal 2, version.id
  end

  def test_import
    PatchKitAPI.expects(:post).with('1/apps/sec/versions?api_key=my_key', params: {}).returns(id: 1)
    version = Version.create(@app)

    params = { source_app_secret: 'source', source_vid: 13 }
    PatchKitAPI.expects(:post).with('1/apps/sec/versions/1/import?api_key=my_key', params: params)
    version.import!(params)
  end

  def test_upload_content
    PatchKitAPI.expects(:post).with('1/apps/sec/versions?api_key=my_key', params: {}).returns(id: 1)
    version = Version.create(@app)

    params = { upload_id: 13 }
    PatchKitAPI.expects(:put)
               .with('1/apps/sec/versions/1/content_file?api_key=my_key', params: params)
    version.upload_content!(params)
  end

  def test_upload_diff
    PatchKitAPI.expects(:post).with('1/apps/sec/versions?api_key=my_key', params: {}).returns(id: 1)
    version = Version.create(@app)

    params = { upload_id: 13, diff_summary: 'abc' }
    PatchKitAPI.expects(:put)
               .with('1/apps/sec/versions/1/diff_file?api_key=my_key', params: params)
    version.upload_diff!(params)
  end
end
