
if "%DEBUG%"=="true" ( echo Debug: Running "%0" )

set GFX_PATH=funk_graphics
set GFX_FILE=funk_graphics\_funk_graphics.z80

if not exist %GFX_PATH%\ (
	rem silent ignore
	goto END
)

REM ==== TELL FATHER ====
echo #define funkmake_graphics_success >> %Temp%

REM ==== CREATE DATA FILE ====
echo ; Funk auto include graphics > %GFX_FILE%
echo .nolist >> %GFX_FILE%
echo .option bm_hdr = TRUE >> %GFX_FILE%
echo .option bm_hdr_fmt="W,H" >> %GFX_FILE%

REM ==== LOOP THROUGH BMPs ====
for /F "tokens=*" %%s in ('dir /b %GFX_PATH%\*.bmp 2^>nul') do (
	echo gfx.%%~ns >> %GFX_FILE%
	echo #include "%GFX_PATH%\%%s" >> %GFX_FILE%
)

REM ==== LOOP THROUGH FOLDERS/BMPs ====
for /F %%f in ('dir /a:d /b %GFX_PATH%\ 2^>nul') do (
	echo gfx.%%f >> %GFX_FILE%
	for /F "tokens=*" %%m in ('dir /b %GFX_PATH%\%%f\*.bmp 2^>nul') do (
		echo gfx.%%f.%%~nm >> %GFX_FILE%
		echo #include "%GFX_PATH%\%%f\%%m" >> %GFX_FILE%
	)
)

echo .option bm_hdr = FALSE >> %GFX_FILE%
echo .list >> %GFX_FILE%

:END
