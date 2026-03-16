@echo off
title Spesho Backend Server
echo ========================================
echo   Spesho Products Management System
echo   Backend API Server
echo ========================================
echo.

cd /d "%~dp0backend"

if not exist "venv\Scripts\activate.bat" (
    echo ERROR: Virtual environment not found at %~dp0backend\venv
    echo Please run setup first.
    pause
    exit /b 1
)

call venv\Scripts\activate.bat

echo Starting Flask server on http://localhost:5000
echo Press Ctrl+C to stop the server
echo.
python run.py

pause
