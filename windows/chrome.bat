@echo off
setlocal

mkdir c:\browsertemp > nul 2>&1
cd c:\browsertemp

echo browser versions supported: https://pptr.dev/supported-browsers
echo.

set /p "version=Enter Version Number (eg 133): "

CMD /C npx -y @puppeteer/browsers install chrome@%version%

cd "c:\browsertemp\chrome\win64-%version%*.*"

for /f "delims=" %%a in ('dir /s /b chrome-win64\chrome.exe') do set "TARGET=%%a"
set SHORTCUT='%userprofile%/Desktop/Google Chrome %version%.lnk'
set PWS=powershell.exe -ExecutionPolicy Bypass -NoLogo -NonInteractive -NoProfile

%PWS% -Command "$ws = New-Object -ComObject WScript.Shell; $s = $ws.CreateShortcut(%SHORTCUT%); $S.TargetPath = '%TARGET%'; $S.Save()"

"chrome-win64\chrome.exe"

endlocal
