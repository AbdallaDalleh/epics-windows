@echo off

set nfs=Z:
set epics_host=windows-x64
set epics=C:\epics
set version=3.15.6
set visual_studio_home=C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build
set perl_home=C:\Strawberry

set release_files=%nfs%\release-files-win64

set EPICS_BASE=%epics%\base
set EPICS_HOST_ARCH=%epics_host%
set support=%epics%\support

if not exist %epics%   mkdir %epics%
if not exist %support% mkdir %support%

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
	echo found perl @ "%perl_home%\perl\bin\perl.exe".
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

REM if not exist %epics%\support\seq\ (
REM 	echo Building sequencer module
REM 	xcopy /i /Y /E %nfs%\seq-2.2.9 %support%\seq >nul 2>&1
REM 	cd %support%\seq
REM 	xcopy /Y %release_files%\seq.RELEASE configure\RELEASE >nul 2>&1
REM 	make >nul 2>&1
REM ) else (
REM 	echo Seq 2.2.9 is already installed.
REM )

call :build_module seq -2.2.9
call :build_module autosave

cd %USERPROFILE%
set PATH=%_path%
exit /B 0

:build_module

if not exist %epics%\support\%~1\ (
	echo Building %~1 module ...
	xcopy /i /Y /E %nfs%\%~1%~2 %support%\%~1 >nul 2>&1
	cd %support%\%~1
	xcopy /Y %release_files%\%~1.RELEASE configure\RELEASE >nul 2>&1
	make >nul 2>&1
) else (
	echo %~1 is already installed.
)
EXIT /B 0