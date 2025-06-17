@echo off

echo ==========
echo %PATH%
echo ==========

set epics_host=windows-x64
set epics=C:\epics
set version=7.0.9
set visual_studio_home=C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build
set perl_home=C:\Strawberry
set release_files=%~dp0\release-files
set bin_files=%~dp0\bin
set support=%epics%\support
set epics_url=https://epics.anl.gov/download/base/base-%version%.tar.gz

set EPICS_BASE=%epics%\base
set EPICS_HOST_ARCH=%epics_host%

set "_path="
set "_path=%PATH%"
set "PATH=%PATH%;C:\make"
set "PATH=%PATH%;%perl_home%\c\bin"
set "PATH=%PATH%;%perl_home%\perl\site\bin"
set "PATH=%PATH%;%perl_home%\perl\bin"

call %~dp0\sanity-check.bat
set "ERROR=%ERRORLEVEL%"
if "%ERROR%"=="0" (
	echo Environment OK!
) else (
	echo Dependecies check faild.
	goto :cleanup
)

if not exist %EPICS_BASE%\ (
	echo Building EPICS Base %version%
	cd %epics%
	C:
	mkdir base

	powershell -command "iwr -outf base-%version%.tar.gz %epics_url%"

	tar -xzvf base-%version%.tar.gz -C base --strip-components=1 >nul 2>&1

	cd base
	make
) else (
	echo EPICS Base is already installed.
)

call :build_module seq           https://github.com/mdavidsaver/sequencer-mirror || goto :cleanup
call :build_module autosave      https://github.com/epics-modules/autosave       || goto :cleanup
call :build_module sscan         https://github.com/epics-modules/sscan          || goto :cleanup
call :build_module calc          https://github.com/epics-modules/calc           || goto :cleanup
call :build_module ipac          https://github.com/epics-modules/ipac           || goto :cleanup
call :build_module asyn          https://github.com/epics-modules/asyn           || goto :cleanup
call :build_module scaler        https://github.com/epics-modules/scaler         || goto :cleanup
call :build_module busy          https://github.com/epics-modules/busy           || goto :cleanup
call :build_module std           https://github.com/epics-modules/std            || goto :cleanup
call :build_module mca           https://github.com/epics-modules/mca            || goto :cleanup
call :build_module ADSupport     https://github.com/areaDetector/ADSupport       || goto :cleanup
call :build_module ADCore        https://github.com/areaDetector/ADCore          || goto :cleanup
call :build_module stream-device https://github.com/paulscherrerinstitute/StreamDevice || goto :cleanup


goto :cleanup

:cleanup

set ERROR=%errorlevel%

cd %USERPROFILE%
set PATH=
set PATH=%_path%
set nfs=
set epics_host=
set epics=
set version=
set visual_studio_home=
set perl_home=
set release_files=
set support=
set ad_base=
set _path=

if %ERROR% neq 0 (
	echo Build failed
)

EXIT /B %ERROR%

:build_module

set module=%~1
set url=%~2
if not exist %support%\%module%\ (
	echo Building %module% module ...
	cd /d %support%
	git clone "%url%" "%module%"
	cd %module%
	echo F | xcopy /Y %release_files%\%module%.RELEASE %support%\%module%\configure\RELEASE
	if %module% == ADCore echo HDF5_STATIC_BUILD=NO>> configure\CONFIG_SITE
	make
) else (
	echo %module% is already installed.
)
if %ERRORLEVEL% equ 0 (
	echo Module %module% built successfully.
)
EXIT /B %ERRORLEVEL%
