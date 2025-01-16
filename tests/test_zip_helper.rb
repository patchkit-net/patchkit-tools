require_relative 'test_helper'
require_relative '../app/core/utils/zip_helper'
require 'fileutils'
require 'tmpdir'
require 'zip'

class TestZipHelper < Test::Unit::TestCase
  def setup
    @temp_dir = Dir.mktmpdir
    @source_dir = File.join(@temp_dir, 'source')
    @zip_file = File.join(@temp_dir, 'test.zip')
    @extract_dir = File.join(@temp_dir, 'extract')
    
    FileUtils.mkdir_p(@source_dir)
    FileUtils.mkdir_p(File.join(@source_dir, 'dir1'))
    
    # Create test files
    File.write(File.join(@source_dir, 'app.exe'), "app content")
    File.write(File.join(@source_dir, 'data.txt'), "data content")
    File.write(File.join(@source_dir, 'dir1/lib.dll'), "lib content")
  end

  def teardown
    FileUtils.remove_entry @temp_dir
  end

  def test_unzip_without_underscores
    # Create zip file
    ZipHelper.zip(@zip_file, {
      File.join(@source_dir, 'app.exe') => 'app.exe',
      File.join(@source_dir, 'data.txt') => 'data.txt',
      File.join(@source_dir, 'dir1/lib.dll') => 'dir1/lib.dll'
    })

    # Extract without underscores
    ZipHelper.unzip(@zip_file, @extract_dir, add_underscores_to_files: false)

    # Verify files were extracted correctly
    assert File.exist?(File.join(@extract_dir, 'app.exe'))
    assert File.exist?(File.join(@extract_dir, 'data.txt'))
    assert File.exist?(File.join(@extract_dir, 'dir1/lib.dll'))
    
    # Verify content
    assert_equal "app content", File.read(File.join(@extract_dir, 'app.exe'))
    assert_equal "data content", File.read(File.join(@extract_dir, 'data.txt'))
    assert_equal "lib content", File.read(File.join(@extract_dir, 'dir1/lib.dll'))
  end

  def test_unzip_with_underscores
    # Create zip file
    ZipHelper.zip(@zip_file, {
      File.join(@source_dir, 'app.exe') => 'app.exe',
      File.join(@source_dir, 'data.txt') => 'data.txt',
      File.join(@source_dir, 'dir1/lib.dll') => 'dir1/lib.dll'
    })

    # Extract with underscores
    ZipHelper.unzip(@zip_file, @extract_dir, add_underscores_to_files: true)

    # Verify files were extracted with underscores (only for files, not directories)
    assert File.exist?(File.join(@extract_dir, 'app.exe_'))
    assert File.exist?(File.join(@extract_dir, 'data.txt_'))
    assert File.exist?(File.join(@extract_dir, 'dir1/lib.dll_'))
    
    # Verify content
    assert_equal "app content", File.read(File.join(@extract_dir, 'app.exe_'))
    assert_equal "data content", File.read(File.join(@extract_dir, 'data.txt_'))
    assert_equal "lib content", File.read(File.join(@extract_dir, 'dir1/lib.dll_'))
  end
end 