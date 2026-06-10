@echo off
echo.
echo   Stopping GuardMe backend...
echo   ---------------------------

CHOICE /C YN /M "  Delete database data as well? (database will be wiped)"
if errorlevel 2 goto nodata
if errorlevel 1 goto withdata

:withdata
echo.
docker compose down -v
goto done

:nodata
echo.
docker compose down
goto done

:done
if %errorlevel% neq 0 (
    echo   [FAILED] Could not stop containers.
    pause
    exit /b 1
)

echo.
echo   Backend stopped.
echo.
pause
