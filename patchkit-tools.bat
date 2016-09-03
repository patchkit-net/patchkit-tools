@echo off

setlocal EnableDelayedExpansion

set TOOL=
set TOOL_NAME=%1

if not [%1] == [] (
  if not "%1:~0,1%" == "-" (
    set TOOL="%~dp0/src/%TOOL_NAME:-=_%.rb"
  )
)

if not [%TOOL%] == [] (
  if exist "%TOOL%" (
    if not "%1" == "--help" (
      if not "%1" == "-h" (
        set TOOL_ARGS=

        :loop
        if "%1"=="" goto after_loop
        set TOOL_ARGS=%TOOL_ARGS% %1
        shift
        goto loop

        :after_loop
        ruby %TOOL%%TOOL_ARGS%
        exit /b ERRORLEVEL
      )
    )
  )
)

echo Usage: patchkit-tools [tool_name] [tool_arguments]
echo.
echo Available tools:
for  %%i in ("%~dp0\src\*.rb") do (
  set z=%%~ni
  echo     !z:_=-!
)
exit /b 1
