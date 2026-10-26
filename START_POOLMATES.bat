@echo off
setlocal
cd /d "%~dp0"
set PORT=8085
set URL=http://localhost:%PORT%/index.html
echo.
echo  PoolMates is starting at %URL%
echo  Leave this window open. Close it (or press Ctrl+C) to stop.
echo.
start "" powershell -WindowStyle Hidden -Command "Start-Sleep 2; Start-Process '%URL%'"
where py >nul 2>nul
if %errorlevel%==0 ( py -m http.server %PORT% & goto done )
where python >nul 2>nul
if %errorlevel%==0 ( python -m http.server %PORT% & goto done )
where node >nul 2>nul
if %errorlevel%==0 ( npx --yes http-server -p %PORT% -c-1 & goto done )
echo  Python/Node not found - opening the page directly from the file instead.
start "" "%CD%\index.html"
:done
echo.
echo  If you saw "address already in use", close the other window using port %PORT% and run this again.
pause
