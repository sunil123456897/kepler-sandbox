@echo off
cd /d "%~dp0"
if exist "..\bin\Godot_v4.7.2-stable_win64.exe" (
    start "" "..\bin\Godot_v4.7.2-stable_win64.exe" --path .
    exit /b 0
)
where godot >nul 2>nul
if %errorlevel%==0 (
    start "" godot --path .
    exit /b 0
)
echo Godot 4.7.2 not found at "..\bin\Godot_v4.7.2-stable_win64.exe" or in PATH.
pause
