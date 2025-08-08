@echo off
setlocal

:: =============================================================================
:: CapRover WSL Installation Script (Windows Host)
:: =============================================================================
:: This script prepares the Windows host and then executes the CapRover
:: installation script inside WSL.
::
:: MUST BE RUN AS ADMINISTRATOR.
::
:: Prerequisites:
:: 1. Windows 10/11 with WSL2 installed.
:: 2. Docker Desktop for Windows (or docker inside WSL) installed and running.
:: 3. The 'setup_caprover_inside_wsl.sh' script must be in the same directory.
:: =============================================================================

echo.
echo [STEP 1 of 3] Checking for Administrator Privileges...

:: Check for Administrator rights
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo ERROR: This script requires Administrator privileges.
    echo Please right-click the file and select "Run as administrator".
    echo.
    pause
    goto:eof
)
echo OK: Administrator privileges detected.

echo.
echo [STEP 2 of 3] Preparing Windows Host Environment...
echo.

REM The IP Helper service on Windows often reserves port 80, which conflicts
REM with the port that CapRover's internal Nginx needs to bind to. We must
REM stop and disable this service to free up the port for Docker/WSL.
echo Stopping and disabling the 'IP Helper' service to free up port 80...
sc stop iphlpsvc >nul
sc config iphlpsvc start=disabled >nul
echo OK: 'IP Helper' service has been stopped and disabled.

echo.
echo [STEP 3 of 3] Handing off to WSL for Docker setup...
echo.

REM First, verify that Docker Desktop is running and accessible from WSL.
echo Verifying Docker is running inside WSL...
wsl -e docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo ERROR: Cannot connect to the Docker daemon from within WSL.
    echo Please ensure Docker Desktop for Windows is running and that
    echo WSL integration is enabled in its settings.
    echo.
    pause
    goto:eof
)
echo OK: Docker daemon is accessible from WSL.
echo.
echo Executing the Linux setup script. Please follow the prompts in the WSL terminal...
echo -----------------------------------------------------------------------------

REM Execute the shell script inside the default WSL distribution.
wsl -e bash ./setup_caprover_inside_wsl.sh

echo -----------------------------------------------------------------------------
echo.
if %errorlevel% equ 0 (
    echo SUCCESS: The CapRover installation script finished.
) else (
    echo ERROR: The CapRover installation script failed. Please review the messages above.
)
echo.
pause
