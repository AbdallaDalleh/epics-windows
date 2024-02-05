@echo off

set epics_host=windows-x64
set epics=C:\epics2
set version=3.15.6
set visual_studio_home=C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build
set perl_home=C:\Strawberry
set release_files=%~dp0\release-files-win64
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
	echo Strawberry Perl not found. Install it and try again.
)

make --version >nul 2>&1 && (
	for /f "delims=" %%a in ('where make') do echo found make @ %%a
) || (
	echo Installing make ...
	if not exist C:\make (
		mkdir C:\make
	)

	xcopy /i /Y /E %~dp0\bin\make.exe C:\make
	xcopy /i /Y /E %~dp0\bin\re2c.exe C:\make
)

set _path=%PATH%
set "PATH=%PATH%;C:\make"
set "PATH=%PATH%;%perl_home%\c\bin"
set "PATH=%PATH%;%perl_home%\perl\site\bin"
set "PATH=%PATH%;%perl_home%\perl\bin"

call "%visual_studio_home%\vcvarsall.bat" x64

exit /B 0

if not exist %EPICS_BASE%\ (
	echo Building EPICS Base %version%
	cd %epics%
	mkdir base
	
	powershell -command "iwr -outf base-%version%.tar.gz %epics_url%"
	
	tar -xzvf base-%version%.tar.gz -C base --strip-components=1
	
	cd base
	make
) else (
	echo EPICS Base is already installed.
)

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
	if %~1 == ADCore echo HDF5_STATIC_BUILD=NO >> configure\CONFIG_SITE
	make
) else (
	echo %~1 is already installed.
)
EXIT /B 0
