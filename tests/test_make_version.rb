require_relative 'test_helper'
require_relative '../app/make_version'

include PatchKitTools::Model

class MakeVersionTest < Test::Unit::TestCase
  def setup
    PatchKitTools::Printer.quiet = true
    ProgressBar.any_instance.stubs(:print)
  end

  def test_with_files_create_version
    tool = PatchKitTools::MakeVersionTool.new(
      "--api-key api_key --secret secret --label 1 --files tests/fixtures/files".split(' ')
    )
    tool.parse_options
    tool.expects(:ask).never

    seq = sequence('seq')

    app = mock('app')
    app.stubs(:secret).returns('secret')

    App.expects(:find_by_secret!).with('secret').returns(app).in_sequence(seq)
    app.expects(:versions).returns([]).in_sequence(seq)

    # create version
    version = mock('version')
    version.stubs(:id).returns(1)
    version.stubs(:draft?).returns(true)

    Version.expects(:create).with(app, label: '1').returns(version).in_sequence(seq)
    version.expects(:label=).with('1').in_sequence(seq)
    version.expects(:save!).in_sequence(seq)

    # upload version
    App.expects(:find_by_secret!).with('secret').returns(app).in_sequence(seq)
    Version.expects(:find_by_id!).with(app, 1).returns(version).in_sequence(seq)

    PatchKitTools::S3Uploader.any_instance.expects(:upload_file).in_sequence(seq)
    PatchKitTools::S3Uploader.any_instance.expects(:upload_id).returns(2).in_sequence(seq)

    version.expects(:upload_content!).with(upload_id: 2).returns(job_guid: 'job-guid').in_sequence(seq)

    # do checks
    PatchKitAPI.expects(:display_job_progress).with('job-guid').in_sequence(seq)
    version.expects(:reload).in_sequence(seq)
    version.expects(:has_processing_error?).returns(false).in_sequence(seq)
    version.expects(:processing_messages).returns(nil).in_sequence(seq)

    tool.execute
  end

  def test_with_files_existing_version
    tool = PatchKitTools::MakeVersionTool.new(
      "--api-key api_key --secret secret --label 1 --overwrite-draft true --files "\
      "tests/fixtures/files".split(' ')
    )
    tool.parse_options
    tool.expects(:ask).never

    seq = sequence('seq')

    app = mock('app')
    app.stubs(:secret).returns('secret')

    App.expects(:find_by_secret!).with('secret').returns(app).in_sequence(seq)

    # existing version
    version = mock('version')
    version.stubs(:id).returns(1)
    version.stubs(:draft?).returns(true)

    app.expects(:versions).returns([version]).in_sequence(seq)

    version.expects(:label=).with('1').in_sequence(seq)
    version.expects(:save!).in_sequence(seq)

    # upload version
    App.expects(:find_by_secret!).with('secret').returns(app).in_sequence(seq)
    Version.expects(:find_by_id!).with(app, 1).returns(version).in_sequence(seq)

    PatchKitTools::S3Uploader.any_instance.expects(:upload_file).in_sequence(seq)
    PatchKitTools::S3Uploader.any_instance.expects(:upload_id).returns(2).in_sequence(seq)

    version.expects(:upload_content!).with(upload_id: 2).returns(job_guid: 'job-guid').in_sequence(seq)

    # do checks
    PatchKitAPI.expects(:display_job_progress).with('job-guid').in_sequence(seq)
    version.expects(:reload).in_sequence(seq)
    version.expects(:has_processing_error?).returns(false).in_sequence(seq)
    version.expects(:processing_messages).returns(nil).in_sequence(seq)

    tool.execute
  end

  def test_with_import
    tool = PatchKitTools::MakeVersionTool.new(
      "--api-key api_key --secret secret --label 1 --import-app-secret source --import-version 14".split(' ')
    )
    tool.parse_options
    tool.expects(:ask).never

    seq = sequence('seq')

    # read source version
    source_app = mock('source_app')
    App.expects(:find_by_secret!).with('source').returns(source_app).in_sequence(seq)

    source_version = mock('source_version')
    Version.expects(:find_by_id!).with(source_app, 14).returns(source_version).in_sequence(seq)

    source_version.expects(:can_be_imported?).returns(true).in_sequence(seq)

    # read target app
    app = mock('app')
    app.stubs(:secret).returns('secret')

    App.expects(:find_by_secret!).with('secret').returns(app).in_sequence(seq)
    app.expects(:versions).returns([]).in_sequence(seq)

    # create version
    version = mock('version')
    version.stubs(:id).returns(1)
    version.stubs(:draft?).returns(true)

    Version.expects(:create).with(app, label: '1').returns(version).in_sequence(seq)
    version.expects(:label=).with('1').in_sequence(seq)
    version.expects(:save!).in_sequence(seq)

    # import version
    version.expects(:import!).with(source_app_secret: 'source', source_vid: 14)
           .returns(job_guid: 'job-guid').in_sequence(seq)

    # do checks
    PatchKitAPI.expects(:display_job_progress).with('job-guid').in_sequence(seq)
    version.expects(:reload).in_sequence(seq)
    version.expects(:has_processing_error?).returns(false).in_sequence(seq)
    version.expects(:processing_messages).returns(nil).in_sequence(seq)

    tool.execute
  end

  def test_with_import_cannot_be_imported
    tool = PatchKitTools::MakeVersionTool.new(
      "--api-key api_key --secret secret --label 1 --import-app-secret source --import-version 14".split(' ')
    )
    tool.parse_options
    tool.expects(:ask).never

    seq = sequence('seq')

    # read source version
    source_app = mock('source_app')
    App.expects(:find_by_secret!).with('source').returns(source_app).in_sequence(seq)

    source_version = mock('source_version')
    Version.expects(:find_by_id!).with(source_app, 14).returns(source_version).in_sequence(seq)

    source_version.expects(:can_be_imported?).returns(false).in_sequence(seq)

    assert_raises(PatchKitTools::CommandLineError, "Source version cannot be imported") { tool.execute }
  end

  def test_with_import_copy_label
    tool = PatchKitTools::MakeVersionTool.new(
      "--api-key api_key --secret secret --import-app-secret source --import-version 14 "\
      "--import-copy-label".split(' ')
    )
    tool.parse_options
    tool.expects(:ask).never

    seq = sequence('seq')

    # read source version
    source_app = mock('source_app')
    App.expects(:find_by_secret!).with('source').returns(source_app).in_sequence(seq)

    source_version = mock('source_version')
    Version.expects(:find_by_id!).with(source_app, 14).returns(source_version).in_sequence(seq)

    source_version.expects(:can_be_imported?).returns(true).in_sequence(seq)

    # read target app
    app = mock('app')
    app.stubs(:secret).returns('secret')

    App.expects(:find_by_secret!).with('secret').returns(app).in_sequence(seq)
    app.expects(:versions).returns([]).in_sequence(seq)

    # create version
    version = mock('version')
    version.stubs(:id).returns(1)
    version.stubs(:draft?).returns(true)

    source_version.expects(:label).returns('source_label').in_sequence(seq)

    Version.expects(:create).with(app, label: 'source_label').returns(version).in_sequence(seq)
    version.expects(:label=).with('source_label').in_sequence(seq)
    version.expects(:save!).in_sequence(seq)

    # import version
    version.expects(:import!).with(source_app_secret: 'source', source_vid: 14)
           .returns(job_guid: 'job-guid').in_sequence(seq)

    # do checks
    PatchKitAPI.expects(:display_job_progress).with('job-guid').in_sequence(seq)
    version.expects(:reload).in_sequence(seq)
    version.expects(:has_processing_error?).returns(false).in_sequence(seq)
    version.expects(:processing_messages).returns(nil).in_sequence(seq)

    tool.execute
  end

  def test_with_import_copy_changelog
    tool = PatchKitTools::MakeVersionTool.new(
      "--api-key api_key --secret secret --import-app-secret source --import-version 14 "\
      "--label 1 --import-copy-changelog".split(' ')
    )
    tool.parse_options
    tool.expects(:ask).never

    seq = sequence('seq')

    # read source version
    source_app = mock('source_app')
    App.expects(:find_by_secret!).with('source').returns(source_app).in_sequence(seq)

    source_version = mock('source_version')
    Version.expects(:find_by_id!).with(source_app, 14).returns(source_version).in_sequence(seq)

    source_version.expects(:can_be_imported?).returns(true).in_sequence(seq)

    # read target app
    app = mock('app')
    app.stubs(:secret).returns('secret')

    App.expects(:find_by_secret!).with('secret').returns(app).in_sequence(seq)
    app.expects(:versions).returns([]).in_sequence(seq)

    # create version
    version = mock('version')
    version.stubs(:id).returns(1)
    version.stubs(:draft?).returns(true)

    Version.expects(:create).with(app, label: '1').returns(version).in_sequence(seq)
    version.expects(:label=).with('1').in_sequence(seq)

    source_version.expects(:changelog).returns('source_changelog').in_sequence(seq)
    version.expects(:changelog=).with('source_changelog').in_sequence(seq)
    version.expects(:save!).in_sequence(seq)

    # import version
    version.expects(:import!).with(source_app_secret: 'source', source_vid: 14)
           .returns(job_guid: 'job-guid').in_sequence(seq)

    # do checks
    PatchKitAPI.expects(:display_job_progress).with('job-guid').in_sequence(seq)
    version.expects(:reload).in_sequence(seq)
    version.expects(:has_processing_error?).returns(false).in_sequence(seq)
    version.expects(:processing_messages).returns(nil).in_sequence(seq)

    tool.execute
  end
end
