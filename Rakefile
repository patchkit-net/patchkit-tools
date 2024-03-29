require 'rake/testtask'
# For Bundler.with_clean_env
require 'bundler/setup'

PACKAGE_NAME = "patchkit-tools"
TRAVELING_RUBY_VERSION = "20210206-2.4.10"
RUBY_DIRECTORY = "packaging/ruby"
VENDOR_DIRECTORY = "packaging/vendor"
TEMP_GEMS_DIRECTORY = "packaging/temp_gems"

desc "Package patchkit-tools"
task :package => ['package:linux:x86_64', 'package:osx', 'package:win32']

namespace :package do
  namespace :linux do
    # desc "Package patchkit-tools for Linux x86"
    # task :x86 => [:bundle_install, "#{RUBY_DIRECTORY}/traveling-ruby-#{TRAVELING_RUBY_VERSION}-linux-x86.tar.gz"] do
    #   create_package("linux-x86")
    # end

    desc "Package patchkit-tools for Linux x86_64"
    task :x86_64 => [:bundle_install, "#{RUBY_DIRECTORY}/traveling-ruby-#{TRAVELING_RUBY_VERSION}-linux-x86_64.tar.gz"] do
      create_package("linux-x86_64")
    end
  end

  desc "Package patchkit-tools for OS X"
  task :osx => [:bundle_install, "#{RUBY_DIRECTORY}/traveling-ruby-#{TRAVELING_RUBY_VERSION}-osx.tar.gz"] do
    create_package("osx")
  end

  desc "Package patchkit-tools for Windows x86"
  task :win32 => [:bundle_install, "#{RUBY_DIRECTORY}/traveling-ruby-#{TRAVELING_RUBY_VERSION}-x86_64-win32.tar.gz"] do
    create_package("x86_64-win32", :windows)
  end

  desc "Install gems to local directory"
  task :bundle_install do
    if RUBY_VERSION !~ /^2\.4\.10/s
      abort "You can only 'bundle install' using Ruby 2.4.10, because that's what Traveling Ruby uses."
    end
    sh "rm -rf #{TEMP_GEMS_DIRECTORY}"
    sh "rm -rf #{VENDOR_DIRECTORY}"
    sh "mkdir -p #{TEMP_GEMS_DIRECTORY}"
    sh "cp Gemfile Gemfile.lock #{TEMP_GEMS_DIRECTORY}/"
    Bundler.with_clean_env do
      sh "cd #{TEMP_GEMS_DIRECTORY} && env BUNDLE_IGNORE_CONFIG=1 bundle install --path vendor --without development"
      sh "cp -r #{TEMP_GEMS_DIRECTORY}/vendor/* #{VENDOR_DIRECTORY}/"
    end
    sh "rm -rf #{TEMP_GEMS_DIRECTORY}"
    sh "rm -f #{VENDOR_DIRECTORY}/*/*/cache/*"
  end
end

file "#{RUBY_DIRECTORY}/traveling-ruby-#{TRAVELING_RUBY_VERSION}-linux-x86_64.tar.gz" do
  download_runtime("linux-x86_64")
end

file "#{RUBY_DIRECTORY}/traveling-ruby-#{TRAVELING_RUBY_VERSION}-osx.tar.gz" do
  download_runtime("osx")
end

file "#{RUBY_DIRECTORY}/traveling-ruby-#{TRAVELING_RUBY_VERSION}-x86_64-win32.tar.gz" do
  download_runtime("x86_64-win32")
end

def create_package(target, os_type = :unix)
  package_dir = "packaging/temp_#{PACKAGE_NAME}-#{target}"

  sh "rm -rf #{package_dir}"

  sh "mkdir -p #{package_dir}/app"
  sh "cp -r app/* #{package_dir}/app/"

  sh "mkdir -p #{package_dir}/config"
  sh "cp config/config.local.yml.sample #{package_dir}/config/"

  sh "mkdir -p #{package_dir}/ruby"
  sh "tar -xzf #{RUBY_DIRECTORY}/traveling-ruby-#{TRAVELING_RUBY_VERSION}-#{target}.tar.gz -C #{package_dir}/ruby"
  
  if os_type == :unix
    # Hack to get paths containing spaces to behave correctly
    # @see https://github.com/phusion/traveling-ruby/issues/38
    # sh %Q{sed -i 's|RUBYOPT=\\\\"-r$ROOT/lib/restore_environment\\\\"|RUBYOPT=\\\\"-rrestore_environment\\\\"|' '#{package_dir}/ruby/bin/ruby_environment'}
    # sh %Q{sed -i 's|GEM_HOME="$ROOT/lib/ruby/gems/2.4.10"|GEM_HOME=\\\\"$ROOT/lib/ruby/gems/2.4.10\\\\"|' '#{package_dir}/ruby/bin/ruby_environment'}
    # sh %Q{sed -i 's|GEM_PATH="$ROOT/lib/ruby/gems/2.4.10"|GEM_PATH=\\\\"$ROOT/lib/ruby/gems/2.4.10\\\\"|' '#{package_dir}/ruby/bin/ruby_environment'}
    # sh "mv #{package_dir}/ruby/lib/restore_environment.rb #{package_dir}/ruby/lib/ruby/2.4.10/restore_environment.rb"

    sh "cp packaging/patchkit-tools #{package_dir}/patchkit-tools"
  else
    sh "cp packaging/StartTools.lnk #{package_dir}/StartTools.lnk"
    sh "cp packaging/setenv.bat #{package_dir}/setenv.bat"
    sh "cp packaging/patchkit-tools.bat #{package_dir}/patchkit-tools.bat"
  end

  sh "mkdir -p #{package_dir}/vendor/ruby"
  sh "cp -r #{VENDOR_DIRECTORY}/* #{package_dir}/vendor/ruby/"
  sh "cp Gemfile Gemfile.lock #{package_dir}/vendor/"

  sh "mkdir -p #{package_dir}/vendor/.bundle"
  sh "cp packaging/bundler-config #{package_dir}/vendor/.bundle/config"

  sh "mkdir -p packaging/output"
  sh "cd #{package_dir} && zip -r package.zip *"
  sh "mv #{package_dir}/package.zip packaging/output/#{PACKAGE_NAME}-#{target}.zip"
  sh "rm -rf #{package_dir}"
end

def download_runtime(target)
  sh "mkdir -p #{RUBY_DIRECTORY}"

  sh "cd #{RUBY_DIRECTORY} && curl -L -O --fail " +
    "http://d6r77u77i8pq3.cloudfront.net/releases/traveling-ruby-#{TRAVELING_RUBY_VERSION}-#{target}.tar.gz"
end


Rake::TestTask.new do |t|
  t.libs << "tests"
  t.test_files = FileList['tests/test*.rb']
  t.verbose = true
end
