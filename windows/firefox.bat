@echo off
setlocal

mkdir c:\browsertemp > nul 2>&1
cd c:\browsertemp

echo browser versions supported: https://pptr.dev/supported-browsers
echo.

set /p "version=Enter Version Number (eg 129.0): "

CMD /C npx -y @puppeteer/browsers install firefox@stable_%version%

"c:\browsertemp\firefox\win64-stable_%version%\core\firefox.exe"


endlocal
