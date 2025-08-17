@echo off
echo Starting Batch Application Development Environment for Windows...
echo.

REM Set environment variables
set NODE_ENV=development
set PORT=8088
set FRONTEND_URL=http://localhost:3001

echo Environment Variables:
echo NODE_ENV=%NODE_ENV%
echo PORT=%PORT%
echo FRONTEND_URL=%FRONTEND_URL%
echo.

REM Check if pnpm is installed
where pnpm >nul 2>nul
if %errorlevel% neq 0 (
    echo Error: pnpm is not installed or not in PATH
    echo Please install pnpm: npm install -g pnpm
    pause
    exit /b 1
)

REM Check if air is installed
where air >nul 2>nul
if %errorlevel% neq 0 (
    echo Error: air is not installed or not in PATH
    echo Please install air: go install github.com/cosmtrek/air@latest
    pause
    exit /b 1
)

echo Starting Next.js frontend on port 3001...
start "Next.js Frontend" cmd /k "cd static && pnpm run dev"

echo Waiting 3 seconds for frontend to start...
timeout /t 3 /nobreak >nul

echo Starting Golang backend with Air on port 8088...
start "Golang Backend" cmd /k "air -c .air.win.toml"

echo.
echo ========================================
echo Development servers are starting...
echo ========================================
echo Frontend (Next.js): http://localhost:3001
echo Backend (Golang):   http://localhost:8088
echo Application:        http://localhost:8088
echo ========================================
echo.
echo Press any key to stop all servers...
pause >nul

echo Stopping development servers...
taskkill /f /im node.exe 2>nul
taskkill /f /im main.exe 2>nul
taskkill /f /im air.exe 2>nul
echo Development servers stopped.
pause
