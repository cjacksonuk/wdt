 @ECHO OFF
:: ------------------------------------------------------------
:: Useful Commands - (C) Christian Jackson support@icthero.co.uk
:: run commands -----------------------------------------------
:: 1
SET version="1.4"
SET versionDate="14/03/25"
::
:: v1 11/07/21 - Initial release
:: V1.2 14/06/24 - added sysprep to get back to OOBE
:: V1.3 14/03/25 - ADDED  owner and grouptage and date 
:: V1.4 14/03/25 - ADDED  device rename and collect drivers option
:: ------------------------------------------------------------
:: ------------------------------------------------------------
:: ideas:
::
::
:: ------------------------------------------------------------
:: 

::try to determin path of files...
for %%D in (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) do if exist %%D:\Get-WindowsAutoPilotInfo.ps1 (set scriptRoot=%%D:\)
cd %scriptRoot%
::%scriptRoot%

::echo Enabling WinRM
PowerShell -NoProfile -ExecutionPolicy Unrestricted -Command Enable-PSRemoting -SkipNetworkProfileCheck -Force

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
endlocal & set "company=%company%" & set "location=%location%" & set "grouptag=%grouptag%" & set "varsFile=%varsFile%"

:: Now the variables are available outside of setlocal
echo Company outside endlocal: %company%
echo Location outside endlocal: %location%
echo Grouptag outside endlocal: %grouptag%
echo VarsFile : 
::pause

echo ............................................
echo .
::

:MENU
cls
echo ........................................................
echo : ICT Hero AutoPilot Script %version% %versionDate% : support@icthero.co.uk
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
IF %M%==90 GOTO installcwc
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
powershell -NoProfile -ExecutionPolicy Unrestricted -File "%scriptRoot%Get-AuditData.ps1" -OutputFile "%scriptRoot%compDetail.csv" -Append -assetNo "%assetNo%" -company "%company%" -location "%location%" -owner "%owner%" -grouptag "%grouptag%"
echo Done!
pause
GOTO MENU

:RUNAUTOPILOT2CSV

echo Gathering AutoPilot Hash
PowerShell -NoProfile -ExecutionPolicy Unrestricted -Command %~dp0Get-WindowsAutoPilotInfo.ps1 -ComputerName $env:computername -OutputFile %~dp0compHash.csv -append
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
PowerShell -NoProfile -ExecutionPolicy Unrestricted -Command %scriptRoot%Get-WindowsAutoPilotInfo.ps1 -Online -AssignedComputerName %assetNo%
echo ...check enrolled...
GOTO AUDIT
GOTO MENU

:Get-AutopilotDiagnostics2
IF NOT EXIST "%~dp0AutopilotDiagnostic.log" (
    echo Creating AutopilotDiagnostic.log...
    echo %date% %time% - %ComputerName% >> "%~dp0AutopilotDiagnostic.log"
    echo ------------------------------ >> "%~dp0AutopilotDiagnostic.log"
) else (
    echo Appending to AutopilotDiagnostic.log...
    echo %date% %time% - %ComputerName% >> "%~dp0AutopilotDiagnostic.log"
    echo ------------------------------ >> "%~dp0AutopilotDiagnostic.log"
)
echo Running Get-AutopilotDiagnostics2.ps1... SCREEN OUTPUT
PowerShell -NoProfile -ExecutionPolicy Unrestricted -Command %scriptRoot%Get-AutopilotDiagnostics2.ps1 -Online
echo Running Get-AutopilotDiagnostics2.ps1... LOG OUTPUT (SAVING TO AutopilotDiagnostic.log)
PowerShell -NoProfile -ExecutionPolicy Unrestricted -Command %scriptRoot%Get-AutopilotDiagnostics2.ps1 -Online 2>&1 >> "%~dp0AutopilotDiagnostic.log"
echo Checks Complete
echo ------------------------------ >> "%~dp0AutopilotDiagnostic.log"
pause
GOTO MENU

:sysprep
::%windir%/system32/sysprep/sysprep.exe /generalize /oobe /shutdown /quiet
%windir%/system32/sysprep/sysprep.exe /oobe /reboot

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


ren "%scriptRoot%compDetail.csv" "compDetail%BackupName%.csv"
ren "%scriptRoot%compHash.csv" "compHash%BackupName%.csv"
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
set "installer=%scriptRoot%ScreenConnect.ClientSetup.msi"

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
msiexec /i "%installer%" /qn /L*V "%scriptRoot%\install_log.txt"

:: Check if installation was successful
if %errorlevel% equ 0 (
    echo ConnectWise Control installed successfully!
) else (
    echo Installation failed with error code %errorlevel%.
    echo Check %scriptRoot%\install_log.txt for details.
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

:: Trim spaces
set "make=%make: =%"
set "model=%model: =%"

:: Define driver path
set "driverPath=%scriptRoot%Drivers\%make%\%model%"

:: Check if the path exists, if not create it
if not exist "%driverPath%" (
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
:: Get the current device name
:: replace with assetNo
:: Rename the computer with the asset number
echo Renaming device to "%assetNo%"...
::PowerShell -Command "Rename-Computer -NewName '%assetNo%' -Force -Restart"
PowerShell -Command "Rename-Computer -NewName '%assetNo%' -Force"
echo operation complete - if successful - You should reboot to apply the changes.
::pause or wait 5 seconds
timeout /t 5
goto :menu

:EXIT
pause
:EOF
cls 
