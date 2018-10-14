require_relative 'test_helper'
require_relative '../app/channel_make_version'

include PatchKitTools::Model

class ChannelMakeVersionTest < Test::Unit::TestCase
  def setup
    PatchKitTools::Printer.quiet = true
    ProgressBar.any_instance.stubs(:print)
  end

  def test_with_files_create_version
    tool = PatchKitTools::ChannelMakeVersionTool.new(
      "--api-key api_key --secret secret --label 1 --changelog 2".split(' ')
    )
    tool.parse_options
    tool.expects(:ask).never

    seq = sequence('seq')

    app = mock('app')
    app.stubs(:is_channel?).returns(true)
    app.stubs(:secret).returns('secret')

    App.expects(:find_by_secret!).with('secret').returns(app).in_sequence(seq)

    group = mock('group')
    group.stubs(:secret).returns('group_secret')
    app.expects(:group).returns(group).in_sequence(seq)

    group_version = mock('version')
    group_version.stubs(:id).returns(1)

    group.expects(:versions).returns([group_version]).in_sequence(seq)

    app.expects(:versions).returns([]).in_sequence(seq)

    # create version
    version = mock('version')
    version.stubs(:id).returns(1)
    version.stubs(:draft?).returns(true)

    Version.expects(:create).with(app, label: '1').returns(version).in_sequence(seq)
    version.expects(:label=).with('1').in_sequence(seq)
    version.expects(:changelog=).with('2').in_sequence(seq)
    version.expects(:save!).in_sequence(seq)

    version.expects(:link_to!)
           .with(source_app_secret: 'group_secret', source_vid: 1).returns(job_guid: 'job-guid')
           .in_sequence(seq)

    PatchKitAPI.expects(:display_job_progress).with('job-guid').in_sequence(seq)

    tool.execute
  end
end
