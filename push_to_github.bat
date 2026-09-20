@echo off
echo =======================================================
echo   Cpanel1280 - Push to GitHub
echo =======================================================
echo.
echo Please create the repository 'Cpanel1280' on github.com if not already created:
echo https://github.com/new
echo (Repository Name: Cpanel1280)
echo.
set /p GITHUB_TOKEN="Enter your GitHub Personal Access Token (or press Enter to try default): "

if "%GITHUB_TOKEN%"=="" (
    git push -u origin main
) else (
    git remote set-url origin https://%GITHUB_TOKEN%@github.com/abbas1280-dev/Cpanel1280.git
    git push -u origin main
    git remote set-url origin https://github.com/abbas1280-dev/Cpanel1280.git
)

echo.
pause
