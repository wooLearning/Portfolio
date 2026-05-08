@echo off
cd /d "%~dp0"

set "PYTHON=python"
where python >nul 2>&1
if errorlevel 1 (
    set "PYTHON=py"
    where py >nul 2>&1
    if errorlevel 1 (
        echo Python was not found. Install Python 3 and enable PATH, then run this again.
        pause
        exit /b 1
    )
)

%PYTHON% -c "import serial, PIL" >nul 2>&1
if errorlevel 1 (
    echo Installing required Python packages...
    %PYTHON% -m pip install -r requirements.txt
    if errorlevel 1 (
        echo.
        echo Failed to install required Python packages.
        pause
        exit /b 1
    )
)

%PYTHON% .\src\interactive_transfer.py
if errorlevel 1 (
    echo.
    echo Transfer exited with an error.
    pause
    exit /b 1
)
