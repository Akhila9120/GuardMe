@echo off
setlocal enabledelayedexpansion

echo.
echo   Your IPv4 Address(es):
echo   ----------------------

for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr "IPv4"') do (
    set ip=%%a
    set ip=!ip:~1!
    echo   !ip!
)

echo.
echo   Use this IP in the GuardMe app Settings or .env file:
echo   API_BASE_URL=http://YOUR_IP:8080
echo.
pause
