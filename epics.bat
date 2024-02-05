@echo off

set nfs=Z:
set epics_host=windows-x64
set epics=C:\epics
set version=3.15.6
set visual_studio_home=C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build
set perl_home=C:\Strawberry
set release_files=%nfs%\release-files-win64
set support=%epics%\support

set EPICS_BASE=%epics%\base
set EPICS_HOST_ARCH=%epics_host%

if not exist %epics%\   mkdir %epics%
if not exist %support%\ mkdir %support%

git --version >nul 2>&1 && (
	for /f "delims=" %%a in ('where git') do echo found git @ %%a
) || (
	echo Git is not installed. Exiting.
	exit /B %ERRORLEVEL%
)

make --version >nul 2>&1 && (
	for /f "delims=" %%a in ('where make') do echo found make @ %%a
) || (
	echo Installing make and re2c from %nfs%\.
	xcopy /i /Y /E %nfs%\make C:\make >nul 2>&1
)

if exist "%perl_home%\perl\bin\perl.exe" (
	echo found perl @ %perl_home%\perl\bin\perl.exe.
) else (
	echo Strawberry Perl not found. Install it and try again.
)

set _path=%PATH%
set "PATH=%PATH%;C:\make\bin"
set "PATH=%PATH%;%perl_home%\c\bin"
set "PATH=%PATH%;%perl_home%\perl\site\bin"
set "PATH=%PATH%;%perl_home%\perl\bin"

call "%visual_studio_home%\vcvarsall.bat" x64

if not exist %epics%\base\ (
	echo Building EPICS Base %version%
	xcopy /i /Y /E %nfs%\base-%version% %epics%\base >nul 2>&1
	cd %epics%\base
	make >nul 2>&1
) else (
	echo EPICS Base is already installed.
)

cd %support%

call :build_module seq,-2.2.9
call :build_module autosave
call :build_module ether-ip
call :build_module sscan
call :build_module calc
call :build_module ipac
call :build_module asyn
call :build_module scaler
call :build_module stream-device
call :build_module modbus
call :build_module busy
call :build_module std
call :build_module mca

call :build_module ADSupport
call :build_module ADCore

cd %USERPROFILE%
call :clear_env
exit /B 0

:clear_env

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

EXIT /B 0

:build_module

if not exist %epics%\support\%~1\ (
	echo Building %~1 module ...
	xcopy /i /Y /E %nfs%\%~1%~2 %support%\%~1 >nul 2>&1
	cd %support%\%~1
	xcopy /Y %release_files%\%~1.RELEASE configure\RELEASE >nul 2>&1
	if %~1 == ADCore (
		echo HDF5_STATIC_BUILD=NO>> configure\CONFIG_SITE
	)
	make >nul 2>&1
) else (
	echo %~1 is already installed.
)
EXIT /B 0
