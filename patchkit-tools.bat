@echo off

:: http://stackoverflow.com/questions/2952401/remove-trailing-slash-from-batch-file-input
set current_dir=%~dp0
IF %current_dir:~-1%==\ SET current_dir=%current_dir:~0,-1%

ruby "%current_dir%\app\lib\bootstrap.rb" %*

set current_dir=