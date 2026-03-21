@echo off
cd /d "%~dp0"
node tools\build-markdown-pdfs.js
if errorlevel 1 (
  echo PDF generation failed.
  exit /b 1
)
echo PDF generation completed.
