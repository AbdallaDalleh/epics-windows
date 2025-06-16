@echo off

if not exist %epics%\     mkdir %epics%;
if not exist %support%\   mkdir %support%;

if exist "%visual_studio_home%\vcvarsall.bat" (
	echo Configuring Visual Studio ...
	call "%visual_studio_home%\vcvarsall.bat" x64
	set "ERROR=%ERRORLEVEL%"
	if not "%ERROR%"=="0" (
		exit /B %ERROR%
	) else (
		echo Environment initialized for x64
	)
) else (
	echo "Visual studio is not be installed. Exiting."
	exit /B 1
)

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
	if %ERRORLEVEL% neq 0 (
		exit /B %ERRORLEVEL%
	)
)

if exist "C:\make\re2c.exe" (
	echo found re2c @ C:\make\re2c.exe
) else (
	echo Installing re2c ...
	if not exist "C:\make" mkdir C:\make

	xcopy /i /Y /E %bin_files%\re2c.exe C:\make >nul 2>&1
	if %ERRORLEVEL% neq 0 (
		exit /B %ERRORLEVEL%
	)
)

exit /B 0