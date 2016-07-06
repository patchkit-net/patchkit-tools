@echo off

set PROGRAM_ARGS=
set PROGRAM_NAME=%1
set PROGRAM_NAME="%~dp0/%PROGRAM_NAME:-=_%.rb"
shift

:loop
if [%1]==[] goto after_loop
set PROGRAM_ARGS=%PROGRAM_ARGS% %1
shift
goto loop

:after_loop
ruby %PROGRAM_NAME%%PROGRAM_ARGS%
