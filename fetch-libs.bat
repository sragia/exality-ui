@echo off
setlocal
cd /d "%~dp0"

set "GIT_BASH=%ProgramFiles%\Git\bin\bash.exe"
if not exist "%GIT_BASH%" (
	echo Git Bash not found. Install Git for Windows.
	exit /b 1
)

"%GIT_BASH%" ./fetch-libs.sh
