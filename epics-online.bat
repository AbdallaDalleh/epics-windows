@echo off

set epics_host=windows-x64
set epics=C:\epics
set version=3.15.6
set visual_studio_home=C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build
set perl_home=C:\Strawberry
set release_files=%~dp0\release-files
set bin_files=%~dp0\bin
set support=%epics%\support
set epics_url=https://epics.anl.gov/download/base/base-%version%.tar.gz

set EPICS_BASE=%epics%\base
set EPICS_HOST_ARCH=%epics_host%

if not exist %epics%\     mkdir %epics%;
if not exist %support%\   mkdir %support%;

git --version >nul 2>&1 && (
	for /f "delims=" %%a in ('where git') do echo found git @ %%a
) || (
	echo Git is not installed. Exiting.
	exit /B %ERRORLEVEL%
)

if exist "%perl_home%\perl\bin\perl.exe" (
	echo found perl @ %perl_home%\perl\bin\perl.exe.
) else (
	echo Strawberry Perl not found.
	exit /B %ERRORLEVEL%
)

if exist "C:\make\make.exe" (
	echo found make @ C:\make\make.exe
) else (
	echo Installing make ...
	if not exist "C:\make" mkdir C:\make

	xcopy /i /Y /E %bin_files%\make.exe C:\make >nul 2>&1
)

if exist "C:\make\re2c.exe" (
	echo found re2c @ C:\make\re2c.exe
) else (
	echo Installing re2c ...
	if not exist "C:\make" mkdir C:\make

	xcopy /i /Y /E %bin_files%\re2c.exe C:\make >nul 2>&1
)

set _path=%PATH%
set "PATH=%PATH%;C:\make"
set "PATH=%PATH%;%perl_home%\c\bin"
set "PATH=%PATH%;%perl_home%\perl\site\bin"
set "PATH=%PATH%;%perl_home%\perl\bin"

if exist "%visual_studio_home%\vcvarsall.bat" (
	call "%visual_studio_home%\vcvarsall.bat" x64
) else (
	echo "Visual studio is not be installed. Exiting."
	exit /B 1
)

if not exist %EPICS_BASE%\ (
	echo Building EPICS Base %version%
	cd %epics%
	mkdir base

	powershell -command "iwr -outf base-%version%.tar.gz %epics_url%"

	tar -xzvf base-%version%.tar.gz -C base --strip-components=1 >nul 2>&1

	cd base
	make
) else (
	echo EPICS Base is already installed.
)

call :build_module seq
call :build_module autosave
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

set module=%~1
if not exist %support%\%module%\ (
	echo Building %module% module ...
	cd %support%
	if %module% == seq (
		powershell -command "iwr -outf seq.tar.gz https://github.com/mdavidsaver/sequencer-mirror/archive/refs/tags/R2-2-9.tar.gz"
		mkdir seq
		tar -xzvf seq.tar.gz -C seq --strip-components=1 >nul 2>&1
	) else if %module% == stream-device (
		git clone "https://github.com/paulscherrerinstitute/StreamDevice" stream-device
	) else if %module:~0,2% == AD (
		git clone "https://github.com/areaDetector/%~1"
	) else (
		git clone "https://github.com/epics-modules/%~1"
	)
	
	cd %support%\%module%
	xcopy /Y %release_files%\%module%.RELEASE configure\RELEASE >nul 2>&1
	if %module% == ADCore echo HDF5_STATIC_BUILD=NO>> configure\CONFIG_SITE
	make
	set module=
) else (
	echo %module% is already installed.
)
EXIT /B 0
