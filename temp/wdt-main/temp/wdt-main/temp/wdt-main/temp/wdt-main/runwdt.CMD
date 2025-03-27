 @ECHO OFF
::try to determin path of files...
for %%D in (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) do if exist %%D:\runwdt.CMD (set scriptRoot=%%D:\)
cd %scriptRoot%


:: Check if the script is running as administrator
::net session >nul 2>&1
::if %errorLevel% neq 0 (
::    echo This script requires administrative privileges. Please run as administrator.
    ::pause
::)

:: Run %scriptRoot%\wdt.cmd as administrator
%scriptRoot%wdt\wdt.cmd
