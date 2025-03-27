@echo off
setlocal enabledelayedexpansion

::try to determin path of files...
for %%D in (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) do if exist %%D:\runwdt.CMD (set scriptRoot=%%D:\wdt)
cd %scriptRoot%
::%scriptRoot%
echo Script Root is: %scriptRoot%
set "rootPath=%~d0\"
echo Root path is: %rootPath%

:: CONFIG
set "REPO_USER=cjacksonuk"
set "REPO_NAME=wdt"
set "LOCAL_VERSION_FILE=%scriptRoot%\wdt\wdt_version.txt"
set "TEMP_DIR=%rootPath%temp"
set "ZIP_URL=https://github.com/%REPO_USER%/%REPO_NAME%/archive/refs/heads/main.zip"
set "REMOTE_VERSION_URL=https://raw.githubusercontent.com/%REPO_USER%/%REPO_NAME%/main/wdt/wdt_version.txt"

:: Ensure TEMP_DIR exists
if not exist "%TEMP_DIR%" (
    mkdir "%TEMP_DIR%"
)

:: Step 1: Check internet
echo Checking internet connection...
ping -n 1 github.com >nul 2>&1 || (
    echo No internet connection. Update aborted.
    exit /b 1
)

:: Step 2: Read local version
echo looking for %LOCAL_VERSION_FILE%
if not exist "%LOCAL_VERSION_FILE%" (
    echo Local version file not found. Assuming version 0.0.0
    set "LOCAL_VERSION=0.0.0"
) else (
    set /p LOCAL_VERSION=<"%LOCAL_VERSION_FILE%"
    echo Local version is !LOCAL_VERSION!
)

:: Step 3: Fetch remote version
echo looking for %REMOTE_VERSION_URL%
for /f "delims=" %%A in ('powershell -Command "try { (Invoke-WebRequest -Uri \"%REMOTE_VERSION_URL%\" -UseBasicParsing).Content } catch { Write-Output \"ERROR\" }"') do set "REMOTE_VERSION=%%A"

if "%REMOTE_VERSION%"=="ERROR" (
    echo Failed to fetch remote version. Update aborted.
    exit /b 1
)
:: Step 4: Compare versions
echo Local version : %LOCAL_VERSION%
echo Remote version: %REMOTE_VERSION%
if "%LOCAL_VERSION%"=="%REMOTE_VERSION%" (
    echo Already up to date!
    exit /b 0
)


:: Step 5: Download latest version ZIP
echo Downloading update...
if exist "%TEMP_DIR%" rd /s /q "%TEMP_DIR%"
mkdir "%TEMP_DIR%"
powershell -Command "(Invoke-WebRequest -Uri \"%ZIP_URL%\" -OutFile \"%TEMP_DIR%\update.zip\")"

:: Step 6: Extract and replace
powershell -Command "Expand-Archive -Path '%TEMP_DIR%\update.zip' -DestinationPath '%TEMP_DIR%' -Force"
echo Updating files...
::robocopy "%TEMP_DIR%\%REPO_NAME%-main" "%scriptRoot%" /E /NFL /NDL /NJH /NJS /NC
echo attempting to place in %scriptRoot%
echo from %TEMP_DIR%\%REPO_NAME%-main to %scriptRoot%
robocopy "%TEMP_DIR%\%REPO_NAME%-main" %rootPath% /E /NFL /NDL /NJH /NJS /NC

:: Step 7: Cleanup
rd /s /q "%TEMP_DIR%"
echo Update complete! Now running version %REMOTE_VERSION%.
pause
exit /b 0
