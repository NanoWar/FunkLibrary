@echo off
echo # Starting Funk build script...
setlocal enableextensions
setlocal enabledelayedexpansion


REM set DEBUG=true


REM ============================
REM GET PARAMETERS / CONFIG
REM ============================

set Options=

if "%~x1"=="config" (
	set ConfigFile=%1
) else (
	if exist "%~n1.config" (
		set ConfigFile=%~n1.config
	) else (
		set ConfigFile=funk.config
	)
)

if exist "%ConfigFile%" (
	echo # Using config file "%ConfigFile%"
	for /f "tokens=1,2 delims==" %%a in (%ConfigFile%) do (
		set key=%%a
		set val=%%b

		rem Remove tabs and spaces
		set key=!key:	=!
		set key=!key: =!
		set val=!val:	=!
		set val=!val: =!

		if "!val!"=="" (
			set val=true
		)

		set val=!val:-= -!
		set !key!=!val!
	)
)

if "%DEBUG%"=="true" (
	echo # Debug mode
) else (
	set DEBUG=false
)

if "%Folder%"=="" (
	rem nothing
) else (
	set ORIG_CD=%CD%
	cd %Folder% 1>nul
)

if "%Source%"=="" (
if "%1"=="" (
	set Count=0
	for /F "tokens=*" %%f in ('dir /b .\*.z80 2^>nul') do (
		set Source=%%f
		set SourceName=%%~nf
		set /a Count+=1
	)
	for /F "tokens=*" %%f in ('dir /b .\*.asm 2^>nul') do (
		set Source=%%f
		set SourceName=%%~nf
		set /a Count+=1
	)
	if "!Count!" NEQ "1" (
		echo Error: Source file is not inferable
		goto ERROR
	)
	echo # Inferring source file "!Source!"
) else (
	if "%ConfigFile%"=="%1" (
		echo Error: Source is not defined in config file
		goto ERROR
	)
	set Source=%1
))

if not exist %Source% (
	echo Error: File "%Source%" not found
	goto ERROR
)

if "%Type%"=="" (
if "%2"=="" (
	set Type=nostub
) else (
	set Type=%2
))

if "%Calc%"=="" (
if "%3"=="" (
	set Calc=ti83p
) else (
	set Calc=%3
))

if "%Name%"=="" (
if "%4"=="" (
	if defined SourceName (
		set Name=%SourceName%
	) else (
		set Name=%~n1
	)
) else (
	set Name=%4
))

if "%Target%"=="" (
	if "%5"=="" (
		set Target=%Name%
	) else (
		set Target=%5
	)
)
if %Type%==app (
	set Target=!Target!.8xk
) else (
	if %Calc%==ti83 (
		set Target=!Target!.83p
	) else (
		set Target=!Target!.8xp
	)
)


REM ============================
REM PREPARE
REM ============================
echo # Preparing "%Name%", running scripts ...
set Temp=_funk_temp.z80
set FunkPath=%~dp0
set FUNK_PATH=%FunkPath:\=/%
echo ;* Funk temporary compile file > %Temp%
if "%DEBUG%"=="true" ( echo #define FUNK_DEBUG >> %TEMP% )
echo #define FUNK_PATH "%FUNK_PATH%" >> %Temp%
echo #include "%FunkPath%funk.z80" >> %Temp%


REM ==== RUN FUNKY SCRIPTS ===
for /F "tokens=*" %%f in ('dir /b "%~dp0scripts"\*.bat') do (
	call "%~dp0scripts\%%f"
)


REM ==== RUN LOCAL SCRIPTS ===
if exist funk_execute\ (
	for /F "tokens=*" %%f in ('dir /b funk_execute\*.bat 2^>nul') do (
		call funk_execute\%%f
	)
)


REM ==== FUNKY ENCLOSURE / HEADER ====
echo .funk "%Name%", %Type%, %Calc% >> %Temp%

if exist funk_header\ (
	if "%DEBUG%"=="true" ( echo Debug: Including folder funk_headers )
	for /F "tokens=*" %%f in ('dir /b funk_header\* 2^>nul') do (
		echo #include "funk_header/%%f" >> %TEMP%
	)
)

echo #include "%Source%" >> %Temp%
echo .funkend >> %Temp%


REM ==== COMPILE ====
if defined ProgramFiles(x86) (
	set bit=64
) else (
	set bit=32
)
set Compiler=%~dp0spasm\spasm-win%bit%.exe

if "%DEBUG%"=="true" (
	echo Debug: Compiling spasm-win%bit%.exe %Source% %Target%%Options%
)

"%Compiler%" "%Temp%" "%Target%" %Options%

if "%Folder%"=="" (
	rem nothing
) else (
	copy /y "%Target%" "%ORIG_CD%\%Target%" 1>nul
)

REM ==== CLEAN ====
if "%DEBUG%"=="false" (
	del _funk_data.z80 2>nul
	del _funk_header.z80 2>nul
	del _funk_delayed.z80 2>nul
	del _funk_setup.z80 2>nul
	del _funk_include.z80 2>nul
	del _temp.z80 2>nul
	del %TEMP% 2>nul
)


REM ==== END ====
goto END

:ERROR
echo There have been errors!

:END
set errorlevel=0
