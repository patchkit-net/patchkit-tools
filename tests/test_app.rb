require_relative 'test_helper'
require_relative '../app/core/model/app'

include PatchKitTools::Model

class AppTest < Test::Unit::TestCase
  def test_find
    PatchKitAPI.api_key = 'my_key'

    PatchKitAPI.expects(:get).with('1/apps/sec?api_key=my_key').returns(name: 'my name', secret: 'sec')
    app = App.find_by_secret!('sec')
    assert_equal 'my name', app.name
  end

  def test_versions
    PatchKitAPI.expects(:get).with('1/apps/sec?api_key=my_key').returns(secret: 'sec')
    app = App.find_by_secret!('sec')

    PatchKitAPI.expects(:get).with('1/apps/sec/versions?api_key=my_key').returns([{ id: 42 }])
    versions = app.versions
    assert_equal 1, versions.size
    assert_equal 42, versions[0].id
  end
end
