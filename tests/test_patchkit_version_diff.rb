require_relative 'test_helper'
require_relative '../app/core/patchkit_version_diff'
require_relative '../app/core/utils/librsync'
require 'fileutils'
require 'tmpdir'
require 'json'

class TestPatchKitVersionDiff < Test::Unit::TestCase
  def setup
    @temp_dir = Dir.mktmpdir
    @files_dir = File.join(@temp_dir, 'files')
    @signatures_dir = File.join(@temp_dir, 'signatures')
    @output_dir = File.join(@temp_dir, 'output')
    @work_dir = File.join(@temp_dir, 'work')
    @fixtures_dir = File.join(File.dirname(__FILE__), 'fixtures/version_diff')
    
    FileUtils.mkdir_p(@files_dir)
    FileUtils.mkdir_p(@signatures_dir)
    FileUtils.mkdir_p(@output_dir)
    FileUtils.mkdir_p(@work_dir)

    # Create version 1 files
    File.write(File.join(@fixtures_dir, 'app.exe.v1'), "Initial app content")
    FileUtils.mkdir_p(File.join(@fixtures_dir, 'dir1'))
    File.write(File.join(@fixtures_dir, 'dir1/lib.dll.v1'), "Initial lib content")

    # Create version 2 files
    File.write(File.join(@fixtures_dir, 'app.exe.v2'), "Modified app content")
    File.write(File.join(@fixtures_dir, 'data.dll.v2'), "New dll content")
    File.write(File.join(@fixtures_dir, 'dir1/lib.dll.v2'), "Modified lib content")

    # Generate signatures for version 1 files using librsync
    Librsync.rs_rdiff_sig(File.join(@fixtures_dir, 'app.exe.v1'), File.join(@fixtures_dir, 'app.exe.sig'), 4096)
    Librsync.rs_rdiff_sig(File.join(@fixtures_dir, 'dir1/lib.dll.v1'), File.join(@fixtures_dir, 'dir1/lib.dll.sig'), 4096)
  end

  def teardown
    FileUtils.remove_entry @temp_dir
  end

  def test_get_diff_summary
    content_files = ['file1.txt', 'file2.txt']
    signature_files = ['file1.txt']
    unchanged_files = []
    output_file_size = 1000
    uncompressed_size = 2000
    compression_method = 'zip'
    encryption_method = 'none'

    summary = JSON.parse(PatchKitVersionDiff.get_diff_summary(
      content_files: content_files,
      signature_files: signature_files,
      unchanged_files: unchanged_files,
      output_file_size: output_file_size,
      uncompressed_size: uncompressed_size,
      compression_method: compression_method,
      encryption_method: encryption_method
    ))

    assert_equal 1000, summary['size']
    assert_equal 2000, summary['uncompressed_size']
    assert_equal 'zip', summary['compression_method']
    assert_equal 'none', summary['encryption_method']
    assert_equal [], summary['unchanged_files']
    assert_equal ['file2.txt'], summary['added_files']
    assert_equal ['file1.txt'], summary['modified_files']
    assert_equal [], summary['removed_files']
  end

  def test_create_diff_with_underscored_signatures
    # Copy version 2 files to files_dir
    FileUtils.cp(File.join(@fixtures_dir, 'app.exe.v2'), File.join(@files_dir, 'app.exe'))
    FileUtils.cp(File.join(@fixtures_dir, 'data.dll.v2'), File.join(@files_dir, 'data.dll'))
    FileUtils.mkdir_p(File.join(@files_dir, 'dir1'))
    FileUtils.cp(File.join(@fixtures_dir, 'dir1/lib.dll.v2'), File.join(@files_dir, 'dir1/lib.dll'))

    # Copy version 1 signatures to signatures_dir with underscores
    FileUtils.cp(File.join(@fixtures_dir, 'app.exe.sig'), File.join(@signatures_dir, 'app.exe_'))
    FileUtils.mkdir_p(File.join(@signatures_dir, 'dir1'))
    FileUtils.cp(File.join(@fixtures_dir, 'dir1/lib.dll.sig'), File.join(@signatures_dir, 'dir1/lib.dll_'))

    output_file = File.join(@output_dir, 'diff.zip')

    result = PatchKitVersionDiff.create_diff(
      @files_dir,
      @signatures_dir,
      @work_dir,
      output_file,
      signatures_are_underscored: true,
      previous_files_hashes: {}
    )

    summary = JSON.parse(result.diff_summary)
    
    assert_equal ['data.dll'], summary['added_files']
    assert_includes summary['modified_files'], 'app.exe'
    assert_includes summary['modified_files'], 'dir1/lib.dll'
    assert_equal [], summary['removed_files']
  end

  def test_create_diff_without_underscored_signatures
    # Copy version 2 files to files_dir
    FileUtils.cp(File.join(@fixtures_dir, 'app.exe.v2'), File.join(@files_dir, 'app.exe'))
    FileUtils.cp(File.join(@fixtures_dir, 'data.dll.v2'), File.join(@files_dir, 'data.dll'))
    FileUtils.mkdir_p(File.join(@files_dir, 'dir1'))
    FileUtils.cp(File.join(@fixtures_dir, 'dir1/lib.dll.v2'), File.join(@files_dir, 'dir1/lib.dll'))

    # Copy version 1 signatures to signatures_dir without underscores
    FileUtils.cp(File.join(@fixtures_dir, 'app.exe.sig'), File.join(@signatures_dir, 'app.exe'))
    FileUtils.mkdir_p(File.join(@signatures_dir, 'dir1'))
    FileUtils.cp(File.join(@fixtures_dir, 'dir1/lib.dll.sig'), File.join(@signatures_dir, 'dir1/lib.dll'))

    output_file = File.join(@output_dir, 'diff.zip')

    result = PatchKitVersionDiff.create_diff(
      @files_dir,
      @signatures_dir,
      @work_dir,
      output_file,
      signatures_are_underscored: false,
      previous_files_hashes: {}
    )

    summary = JSON.parse(result.diff_summary)
    
    assert_equal ['data.dll'], summary['added_files']
    assert_includes summary['modified_files'], 'app.exe'
    assert_includes summary['modified_files'], 'dir1/lib.dll'
    assert_equal [], summary['removed_files']
  end
end 