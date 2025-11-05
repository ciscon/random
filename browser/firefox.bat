@echo off
setlocal

mkdir c:\browsertemp > nul 2>&1
cd c:\browsertemp

echo browser versions supported: https://pptr.dev/supported-browsers
echo.

set /p "version=Enter Version Number (eg 129.0): "

CMD /C npx -y @puppeteer/browsers install firefox@stable_%version%

set TARGET='c:\browsertemp\firefox\win64-stable_%version%\core\firefox.exe'
set SHORTCUT='%userprofile%/Desktop/Firefox %version%.lnk'
set PWS=powershell.exe -ExecutionPolicy Bypass -NoLogo -NonInteractive -NoProfile

%PWS% -Command "$ws = New-Object -ComObject WScript.Shell; $s = $ws.CreateShortcut(%SHORTCUT%); $S.TargetPath = %TARGET%; $S.Save()"

echo disabled >> "c:\browsertemp\firefox\win64-stable_%version%\core\update-settings.ini"

"c:\browsertemp\firefox\win64-stable_%version%\core\firefox.exe"


endlocal
