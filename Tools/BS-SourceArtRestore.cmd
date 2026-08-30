@echo off
setlocal
chcp 65001 >nul
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0SourceArtBackup\Invoke-SourceArtRestore.ps1" %*
exit /b %ERRORLEVEL%
