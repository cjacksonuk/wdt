 @ECHO OFF
:: ------------------------------------------------------------
:: Useful Commands - (C) Christian Jackson support@icthero.co.uk
:: run commands -----------------------------------------------
:: 
:: v1.0.0 11/07/21 - Initial release
:: V1.0.2 14/06/24 - added sysprep to get back to OOBE
:: V1.0.3 14/03/25 - ADDED  owner and grouptage and date 
:: V1.0.4 14/03/25 - ADDED  device rename and collect drivers option
:: V1.0.5 27/03/25 - ADDED  check for update / relocated files to wdt folder
:: V1.0.6 31/03/25 - Bugfix - issue writing to csv
:: V1.0.7 02/07/25 - Add ms-settings - convienience to open wifi and display controls (for devices with wrong orientation)
:: V1.0.8 09/09/25 - Added ability to ignore cert - required to install nuget from onegetcdn.azureedge.net
:: ------------------------------------------------------------

::try to determin path of files...
for %%D in (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) do if exist %%D:\runwdt.CMD (set scriptRoot=%%D:\wdt)
cd %scriptRoot%
::%scriptRoot%
echo Script Root is: %scriptRoot%
set "rootPath=%~d0\"
echo Root path is: %rootPath%

setlocal enabledelayedexpansion
:: check update
:: CONFIG - for checking if update is available
set "REPO_USER=cjacksonuk"
set "REPO_NAME=wdt"
set "LOCAL_VERSION_FILE=%scriptRoot%\wdt_version.txt"
set "REMOTE_VERSION_URL=https://raw.githubusercontent.com/%REPO_USER%/%REPO_NAME%/main/wdt/wdt_version.txt"
endlocal & set "REPO_USER=%REPO_USER%" & set "REPO_NAME=%REPO_NAME%" & set "LOCAL_VERSION_FILE=%LOCAL_VERSION_FILE%" & set "REMOTE_VERSION_URL=%REMOTE_VERSION_URL%"

::echo Enabling WinRM
::PowerShell -NoProfile -ExecutionPolicy Unrestricted -Command Enable-PSRemoting -SkipNetworkProfileCheck -Force

powershell -NoProfile -ExecutionPolicy Unrestricted -File "%scriptRoot%\prerun.ps1"


::detect if script is running as an admin - if not display message and exit - if running as admin display message and continue
:: Check if the script is running as an administrator
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ------------------------------------------------------------------------------
    echo This script requires administrative privileges. Please run as administrator.
    echo if you continue there may be limited functionality.
    echo ------------------------------------------------------------------------------
    set adminRights=false
    pause
) else (
    echo Script is running with administrative privileges. Continuing...
    set adminRights=true
)


set assetNO=%ComputerName%
set defaultAssetNo=%ComputerName%

:: Get the current date and time in a reliable format
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set "datetime=%%I"

:: Extract required parts
set "YYYY=%datetime:~0,4%"
set "MM=%datetime:~4,2%"
set "DD=%datetime:~6,2%"
set "HH=%datetime:~8,2%"
set "MI=%datetime:~10,2%"
set "SS=%datetime:~12,2%"

:: Format as yyyy-MM-dd HH:mm:ss
set "TIMESTAMP=%YYYY%-%MM%-%DD% %HH%:%MI%:%SS%"

:: Display the timestamp
echo %TIMESTAMP%

set defaultLoggedInUser=%USERNAME%

:: create a vars.txt file %scriptRoot% if not exist, 
:: and populate it with company,location,grouptag variables 
:: if they get updated later in the script we will update the file
:: if they dont exist we will ask the user to populate them

setlocal enabledelayedexpansion
:: check if there is an internet connect and set flag
echo Checking internet connection...
ping -n 1 github.com >nul 2>&1
if errorlevel 1 (
    echo No internet connection. Update check aborted.
    set "internetAvailable=false"
) else (
    echo Internet connection detected. Able to check for updates...
    set "internetAvailable=true"
) 
:: end of check internet

:: Ensure scriptRoot has a trailing backslash
if not "%scriptRoot:~-1%"=="\" set "scriptRoot=%scriptRoot%\"

:: Define vars.txt path
set "varsFile=%scriptRoot%vars.txt"

:: Check if vars.txt exists
if not exist "%varsFile%" (
    echo company=changeme> "%varsFile%"
    echo location=changeme>> "%varsFile%"
    echo grouptag=>> "%varsFile%"
    echo vars.txt created with default values.
    echo Default values set.
) else (
    echo Loading variables from %varsFile%...

    :: Read variables and store them correctly
    for /f "tokens=1,* delims==" %%A in (%varsFile%) do (
        set "%%A=%%B"
    )

    :: Display variables correctly
    echo company=!company!
    echo location=!location!
    echo grouptag=!grouptag!
)

:: Pass variables outside endlocal
endlocal & set "company=%company%" & set "location=%location%" & set "grouptag=%grouptag%" & set "varsFile=%varsFile%" & set "internetAvailable=%internetAvailable%" 

:: continue check for update
:: if internet is available then check for update
if "%internetAvailable%"=="true" (
echo  attempt to check for update
setlocal enabledelayedexpansion
  ::getting local version
   echo looking for %REMOTE_VERSION_URL%
    for /f "delims=" %%A in ('powershell -Command "try { (Invoke-WebRequest -Uri \"%REMOTE_VERSION_URL%\" -UseBasicParsing).Content } catch { Write-Output \"ERROR\" }"') do set "REMOTE_VERSION=%%A"
if "%REMOTE_VERSION%"=="ERROR" (
        echo Failed to fetch remote version. Update check aborted.
        set "updateAvailable=false"
    ) else (
        ::getting local version
        echo looking for %LOCAL_VERSION_FILE%
        if not exist "%LOCAL_VERSION_FILE%" (
            echo Local version file not found. Assuming version 0.0.0
            set "LOCAL_VERSION=0.0.0"
        ) else (
            set /p LOCAL_VERSION=<"%LOCAL_VERSION_FILE%"
            ::echo Local version found: %LOCAL_VERSION%
            echo Local version found: !LOCAL_VERSION!
        )
    )

   ) else ( echo not checking update)
   endlocal & set "REMOTE_VERSION=%REMOTE_VERSION%" & set "updateAvailable=%updateAvailable%" & set "LOCAL_VERSION=%LOCAL_VERSION%" & set "LOCAL_VERSION_FILE=%LOCAL_VERSION_FILE%"
:: end of check for update

:: Now the variables are available outside of setlocal
echo Company outside endlocal: %company%
echo Location outside endlocal: %location%
echo Grouptag outside endlocal: %grouptag%
echo VarsFile : %varsFile%
::pause

::echo ............................................
::echo .
::

:MENU
::cls
echo ........................................................
:: if the update is available then display message current version and available version number
:: Compare the versions
if "%LOCAL_VERSION%" NEQ "%REMOTE_VERSION%" (
    echo UPDATE AVAILABLE! Current version: %LOCAL_VERSION% Available version: %REMOTE_VERSION%
    echo key in option 98 to update
    echo ........................................................
)
::echo : ICT Hero AutoPilot Script %version% %versionDate% : support@icthero.co.uk
echo : ICT Hero WDT Version %LOCAL_VERSION% : support@icthero.co.uk
echo : Timestamp : %TIMESTAMP%
echo : Asset = %assetNo%
echo : Company = %company%
echo : Location = %location%
echo : ScriptRoot = %scriptRoot%
echo : Logged in User = %defaultLoggedInUser%
echo :
echo Select options:
echo ........................................................
echo . 
echo 1 - Change Asset and Location (also renames PC)
echo 2 - Audit Device only
echo 3 - Audit and Get AutoPilot data hash to csv 
echo 4 - Audit and Run AutoPilot Online (Need AAD Credentials)
echo 5 - Get-AutopilotDiagnostics2 (can be run with and with out -online)
echo 6 - Sysprep - Reset to OOBE
echo 7 - SYSTEM RESET - Wipes all data
echo 8 - DELETE ALL DATA
echo 10 - Get drivers for WDS
::echo 11 - Set - Rename device - not needed as option 1 does this now too
echo 80 - Display Settings - start ms-settings:display
echo 81 - Connect to WiFi - start ms-settings:network-wifi
echo 90 - Install Connectwise Control (Do opt 1 first!)
echo 99 - Exit
echo ............................................
echo .

SET /P M=Type 1,2,3,4,5,6,7,8, or 9 Then press ENTER:


IF %M%==1 GOTO CHANGEASSET
IF %M%==2 GOTO AUDIT
IF %M%==3 GOTO RUNAUTOPILOT2CSV
IF %M%==4 GOTO RUNAUTOPILOT2ONLINE
IF %M%==5 GOTO Get-AutopilotDiagnostics2
IF %M%==6 GOTO SYSPREP
IF %M%==7 GOTO SYSTEMRESET
IF %M%==8 GOTO DELETEDATA
IF %M%==10 GOTO GetDrivers
IF %M%==11 GOTO SetDeviceName
IF %M%==80 GOTO MsSettingsDisplay
IF %M%==81 GOTO MsSettingsWiFi
IF %M%==90 GOTO installcwc
IF %M%==98 GOTO updateSoftware
IF %M%==99 GOTO EOF

:CHANGEASSET
::set /P assetNo="Enter Asset Number: " 
set /P assetNo="Enter Asset Number [%assetNo%]: "
    if "%assetNo%"=="" set "assetNo=%defaultAssetNo%"
set /P company="Enter Company Name [%company%]: "
    if "%company%"=="" set "company=changeme"
set /P location="Enter Office Location [%location%]: " 
    if "%location%"=="" set "location=changeme"
set /P grouptag="BETA Enter grout tag [%grouptag%]: "
    if "%grouptag%"=="" set "grouptag=" 
set /P owner="Enter users friendly name [%defaultLoggedInUser%]: "
    if "%owner%"=="" set "owner=%defaultLoggedInUser%"
::set /P company="Company Name: " 

::write the new vars back to the vars.txt file
echo company=%company%> "%varsFile%"
echo location=%location%>> "%varsFile%"
echo grouptag=%grouptag%>> "%varsFile%"
GOTO SetDeviceName
pause
GOTO MENU

:AUDIT
::capture asset data
echo ...logging data for asset collection
:PowerShell -NoProfile -ExecutionPolicy Unrestricted -Command %~dp0Get-OtherData2.ps1 -OutputFile %~dp0compDetail.csv -append -assetNo %assetNo% %location%
:PowerShell -NoProfile -ExecutionPolicy Unrestricted -Command %scriptRoot%Get-AuditData.ps1 -OutputFile %scriptRoot%compDetail.csv -append -assetNo "%assetNo%" "%company%" "%location%" "%owner%" "%grouptag%"
:powershell -NoProfile -ExecutionPolicy Unrestricted -File "%scriptRoot%Get-AuditData.ps1" -OutputFile "%scriptRoot%compDetail.csv" -Append:$true -assetNo "%assetNo%" -company "%company%" -location "%location%" -owner "%owner%" -grouptag "%grouptag%"
powershell -NoProfile -ExecutionPolicy Unrestricted -File "%scriptRoot%\Get-AuditData.ps1" -OutputFile "%rootPath%WDTcompDetail.csv" -Append -assetNo "%assetNo%" -company "%company%" -location "%location%" -owner "%owner%" -grouptag "%grouptag%"
echo Done!
pause
GOTO MENU

:RUNAUTOPILOT2CSV

echo Gathering AutoPilot Hash
::PowerShell -NoProfile -ExecutionPolicy Unrestricted -Command %~dp0Get-WindowsAutoPilotInfo.ps1 -ComputerName $env:computername -OutputFile %rootPath%WDTcompHash.csv -append
PowerShell -NoProfile -ExecutionPolicy Unrestricted -Command %~dp0Get-WindowsAutoPilotInfo.ps1 -ComputerName $env:computername -OutputFile "%rootPath%WDTcompHash.csv" -append
echo ...Hash Collected!
GOTO AUDIT
GOTO MENU


::prepare for online
:: add to group tag? only works online
:ADDTOGROUPTAG
:: is it possible to list all group tags?
:: select one
:: then add to the online enrol



:RUNAUTOPILOT2ONLINE
echo Enroling online

::ASK if user wnats to add to a group tag
::GOTO ADDTOGROUPTAG

:PowerShell -NoProfile -ExecutionPolicy Unrestricted -Command %~dp0Get-WindowsAutoPilotInfo.ps1 -ComputerName $env:computername -OutputFile %~dp0compHash.csv -append
:PowerShell -NoProfile -ExecutionPolicy Unrestricted -Command %scriptRoot%Get-WindowsAutoPilotInfo.ps1 -Online -AssignedComputerName %assetNo%
PowerShell -NoProfile -ExecutionPolicy Unrestricted -Command %~dp0Get-WindowsAutoPilotInfo.ps1 -Online -AssignedComputerName %assetNo%
echo ...check enrolled...
GOTO AUDIT
GOTO MENU

:Get-AutopilotDiagnostics2
::IF NOT EXIST "%~dp0AutopilotDiagnostic.log" (
IF NOT EXIST "%rootPath%AutopilotDiagnostic.log" (
    echo Creating AutopilotDiagnostic.log...
    ::echo %date% %time% - %ComputerName% >> "%~dp0AutopilotDiagnostic.log"
    ::echo ------------------------------ >> "%~dp0AutopilotDiagnostic.log"
    echo %date% %time% - %ComputerName% >> "%rootPath%AutopilotDiagnostic.log"
    echo ------------------------------ >> "%rootPath%AutopilotDiagnostic.log"
) else (
    echo Appending to AutopilotDiagnostic.log...
    
    ::echo %date% %time% - %ComputerName% >> "%~dp0AutopilotDiagnostic.log"
    ::echo ------------------------------ >> "%~dp0AutopilotDiagnostic.log"
    echo %date% %time% - %ComputerName% >> "%rootPath%AutopilotDiagnostic.log"
    echo ------------------------------ >> "%rootPath%AutopilotDiagnostic.log"

)
echo Running Get-AutopilotDiagnostics2.ps1... SCREEN OUTPUT
:PowerShell -NoProfile -ExecutionPolicy Unrestricted -Command %scriptRoot%Get-AutopilotDiagnostics2.ps1 -Online
PowerShell -NoProfile -ExecutionPolicy Unrestricted -Command %~dp0Get-AutopilotDiagnostics2.ps1 -Online

echo Running Get-AutopilotDiagnostics2.ps1... LOG OUTPUT (SAVING TO AutopilotDiagnostic.log)
:PowerShell -NoProfile -ExecutionPolicy Unrestricted -Command %scriptRoot%Get-AutopilotDiagnostics2.ps1 -Online 2>&1 >> "%~dp0AutopilotDiagnostic.log"
:PowerShell -NoProfile -ExecutionPolicy Unrestricted -Command %~dp0Get-AutopilotDiagnostics2.ps1 -Online 2>&1 >> "%~dp0AutopilotDiagnostic.log"
PowerShell -NoProfile -ExecutionPolicy Unrestricted -Command %~dp0Get-AutopilotDiagnostics2.ps1 -Online 2>&1 >> "%rootPath%AutopilotDiagnostic.log"
echo Checks Complete
::echo ------------------------------ >> "%~dp0AutopilotDiagnostic.log"
echo ------------------------------ >> "%rootPath%AutopilotDiagnostic.log"
pause
GOTO MENU

:sysprep
::%windir%/system32/sysprep/sysprep.exe /generalize /oobe /shutdown /quiet
%windir%/system32/sysprep/sysprep.exe /oobe /reboot
echo If this fails, obviously check the logs - but it might be in audit mode; waiting to complete Windows Update!
pause
GOTO MENU

:: build in option to erase data
:DELETEDATA
echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
echo Are you sure you want to delete inventory?
SET /P X=Type y,n Then Press ENTER:
IF %X%==y GOTO DELETEYES
IF %X%==n GOTO DELETENO
:DELETENO
echo "returning to menu -no deletion"
pause
GOTO MENU
:DELETEYES
::actually rename with timestamp for recovery 
for /f "delims=" %%a in ('wmic OS Get localdatetime ^| find "."') do set DateTime=%%a
set Yr=%DateTime:~0,4%
set Mon=%DateTime:~4,2%
set Day=%DateTime:~6,2%
set Hr=%DateTime:~8,2%
set Min=%DateTime:~10,2%
set Sec=%DateTime:~12,2%
set BackupName=_old_%Yr%%Mon%%Day%%Hr%%Min%%Sec%


ren "%rootPath%compDetail.csv" "compDetail%BackupName%.csv"
ren "%rootPath%compHash.csv" "compHash%BackupName%.csv"
echo deleted!
pause
GOTO MENU



:SYSTEMRESET
echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
echo Are you sure you want to RESET SYSTEM?
SET /P X=Type y,n Then Press ENTER:
IF %X%==y GOTO SYSTEMRESETYES
IF %X%==n GOTO SYSTEMRESETNO
:SYSTEMRESETNO
echo "returning to menu -no reset"
pause
GOTO MENU
:SYSTEMRESETYES
systemreset -cleanpc
echo Reset!
pause
shutdown.exe /r /t 5
GOTO MENU

:installcwc
@echo off
setlocal enabledelayedexpansion

:: Ensure scriptRoot is set
if not defined scriptRoot set "scriptRoot=%~dp0"

:: Ensure company and location are set
if not defined company set "company=DefaultCompany"
if not defined location set "location=DefaultLocation"

:: Encode company and location (replace spaces with %20)
for /f "delims=" %%I in ('powershell -NoProfile -Command "[uri]::EscapeDataString('%company%')"') do set "companyUrl=%%I"
for /f "delims=" %%I in ('powershell -NoProfile -Command "[uri]::EscapeDataString('%location%')"') do set "locationUrl=%%I"
::set "companyUrl=%company: =%%20%"
::set "locationUrl=%location: =%%20%"

:: Construct the correct download URL (no need for `^&` escaping)
set "msiUrl=https://icthero.screenconnect.com/Bin/ScreenConnect.ClientSetup.msi?e=Access&y=Guest&c=%companyUrl%&c=%locationUrl%&c=&c=&c=&c=&c=&c="

:: Define where to save the MSI file
set "installer=%~dp0ScreenConnect.ClientSetup.msi"

:: Debugging - Show URL before download
echo Downloading from: "%msiUrl%"
echo Saving as: "%installer%"
::pause

:: Use PowerShell to download the MSI (encapsulated properly)
powershell -Command "& { (New-Object System.Net.WebClient).DownloadFile('%msiUrl%', '%installer%') }"

:: Verify if the MSI downloaded successfully
if not exist "%installer%" (
    echo Error: Failed to download the installer.
    pause
    goto :menu
)

:: Install silently with logging
echo Installing ConnectWise Control...
msiexec /i "%installer%" /qn /L*V "%rootPath%install_log.txt"

:: Check if installation was successful
if %errorlevel% equ 0 (
    echo ConnectWise Control installed successfully!
) else (
    echo Installation failed with error code %errorlevel%.
    echo Check %rootPath%install_log.txt for details.
)

pause
goto :menu

:GetDrivers
:: get device make store in $make
:: get and device model store in $model
:: create the path scriptRoot/Drivers/$make/$model
:: check if the path exists if not create it
:: get drivers for $make $model
:: store in scriptRoot/Drivers/$make/$model
:: compress the folder
:: store in scriptRoot/Drivers/$make/$model.zip
echo Getting drivers for WDS
:: Get device make and model
for /f "tokens=2 delims==" %%I in ('wmic computersystem get manufacturer /value') do set "make=%%I"
for /f "tokens=2 delims==" %%I in ('wmic computersystem get model /value') do set "model=%%I"

:: Sanitize make and model
set "make=%make: =%"
set "model=%model: =%"
set "make=%make:.=%"
set "model=%model:.=%"
set "make=%make:\=_%"
set "model=%model:\=_%"


:: Define driver path
set "driverPath=%rootPath%Drivers\%make%\%model%"

:: Check if the path exists, if not create it
if not exist "%driverPath%" (
    echo Error: The directory "%driverPath%" does not exist. Creating it now...
    mkdir "%driverPath%"
)

:: Get drivers and store in the path
echo Exporting drivers to "%driverPath%"...
PowerShell -Command "Export-WindowsDriver -Online -Destination '%driverPath%'"


::do you want to compress the folder?
:: if yes compress the folder
:: if no go to menu
set /P compress="Do you want to compress the folder? [Y/N]: "
if /i "%compress%"=="Y" goto :CompressFolderDrivers
if /i "%compress%"=="N" goto :dontCompressFolderDrivers

:CompressFolderDrivers
:: Compress the folder
echo Compressing drivers folder...
PowerShell -Command "Compress-Archive -Path '%driverPath%\*' -DestinationPath '%driverPath%.zip' -Force"

:dontCompressFolderDrivers
echo Drivers exported!
timeout /t 5
goto :menu

:SetDeviceName
:: change name of the PC
if "%adminRights%"=="false" (
    echo Renaming PC requires administrative privileges. Please run as administrator.
    echo any other function should be completed eg audit
    pause
) 

if "%adminRights%"=="true" (
    :: Enable delayed expansion for runtime variable modification
    setlocal enabledelayedexpansion

    :: Strip out spaces from assetNo and replace with a hyphen
    set "assetNo=!assetNo: =-!"

    :: Compare the current name with the desired new name
    if /i "%ComputerName%"=="!assetNo!" (
        echo The current computer name "%ComputerName%" is the same as the desired name "!assetNo!". Skipping rename.
    ) else (
        :: Display the updated assetNo
        echo Attempting to rename device to "!assetNo!"...

        :: Rename the computer
        PowerShell -Command "Rename-Computer -NewName '!assetNo!' -Force"

        :: Notify the user
        echo Operation complete - if successful, you should reboot to apply the changes.
    )

    :: End delayed expansion
    endlocal
)

::pause or wait 5 seconds
timeout /t 5
goto :menu

:MsSettingsDisplay
start ms-settings:display
goto :menu
:MsSettingsWiFi
start ms-settings:network-wifi
goto :menu

:updateSoftware
:: start in a new process
start %rootPath%wdt\wdt_update.bat
::%rootPath%wdt\wdt_update.bat
echo closing app so upate can run...
 exit /b 1
goto :menu


:EXIT
pause
:EOF
cls 
