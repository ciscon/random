@echo off
setlocal

mkdir c:\browsertemp > nul 2>&1
cd c:\browsertemp

echo browser versions supported: https://pptr.dev/supported-browsers
echo.

set /p "version=Enter Version Number (eg 133): "

CMD /C npx -y @puppeteer/browsers install chrome@%version%

cd "c:\browsertemp\chrome\win64-%version%*.*"
"chrome-win64\chrome.exe"


endlocal


