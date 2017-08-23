@echo off

@echo off

:: http://stackoverflow.com/questions/2952401/remove-trailing-slash-from-batch-file-input
set current_dir=%~dp0
IF %current_dir:~-1%==\ SET current_dir=%current_dir:~0,-1%

:: Tell Bundler where the Gemfile and gems are.
set BUNDLE_GEMFILE="%current_dir%\vendor\Gemfile"
set BUNDLE_IGNORE_CONFIG=

:: Run the actual app using the bundled Ruby interpreter, with Bundler activated.
@"%current_dir%\ruby\bin\ruby.bat" -rbundler/setup "%current_dir%\app\lib\bootstrap.rb" %*

set current_dir=