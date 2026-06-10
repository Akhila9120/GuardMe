@echo off
echo.
echo   Starting GuardMe backend...
echo   ----------------------------

docker compose up -d

if %errorlevel% neq 0 (
    echo.
    echo   [FAILED] Could not start containers.
    echo   Run: docker compose logs
    echo.
    pause
    exit /b 1
)

echo.
echo   Backend starting -- this may take 2-3 minutes on first run.
echo.
echo   Check health:
echo     curl http://localhost:8080/management/health
echo.
echo   View logs:
echo     docker compose logs -f
echo.
pause
