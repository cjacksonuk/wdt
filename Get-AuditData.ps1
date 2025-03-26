<#
-- audit computer ---------------------------------------------
--
-- v1 11/07/21
-- v1.1 17/03/25 add mor vars
-- Christian Jackson cj@icthero.co.uk
--
Typing this into powershell will give you lots of data to audit
Get-WmiObject -Class Win32_computersystem | Format-List *
Get-WmiObject -Class Win32_BIOS | Format-List *
Get-WmiObject -Class Win32_OperatingSystem | Format-List *
Get-WmiObject -Class Win32_OperatingSystem | Format-List *
---------------------------------------------------------------
#>
#%assetNo% %company% %location% %owner% %grouptag%
[CmdletBinding(DefaultParameterSetName = 'Default')]
param(
[Parameter(Mandatory=$False)] [Switch] $Append = $false,
[Parameter(Mandatory=$False)] [String] $OutputFile = "",
[Parameter(Mandatory=$False)] [String] $assetNo = "",
[Parameter(Mandatory=$False)] [String] $company = "",
[Parameter(Mandatory=$False)] [String] $location = "",
[Parameter(Mandatory=$False)] [String] $owner = "",
[Parameter(Mandatory=$False)] [String] $grouptag = ""
)
# Force the output to a file
        if ($OutputFile -eq "")
        {
            $OutputFile = "$($env:TEMP)\compDetail.csv"
            Write-Host "Output file not specified, using $OutputFile"
        } 
#pass in assetNo
        if ($assetNo -eq "")
        {
            $assetNO = "n/a"
        } 
#pass in cpmpany
        if ($company -eq "")
        {
            $company = "n/a"
        }         
#pass in location
        if ($location -eq "")
        {
            $location = "n/a"
        } 
#pass in owner
        if ($owner -eq "")
        {
            $owner = "n/a"
        }  
#pass in grouptag
        if ($grouptag -eq "")
        {
            $grouptag = "n/a"
        }                

# put various details into array
$ComputerSystem = Get-WmiObject -Class Win32_ComputerSystem | Select -Property Model , Description , PrimaryOwnerName , SystemType, username, SystemFamily, Domain
$BootConfiguration = Get-WmiObject -Class Win32_BootConfiguration | Select -Property Name , ConfigurationPath 
$BIOS = Get-WmiObject -Class Win32_BIOS | Select -Property PSComputerName , Manufacturer , Version , SerialNumber
#$OperatingSystem = Get-WmiObject -Class Win32_OperatingSystem | Select -Property Caption , CSDVersion , OSArchitecture , OSLanguage  
$OS = Get-WmiObject -Class Win32_OperatingSystem | Select -Property Caption , CSDVersion , OSArchitecture , OSLanguage  
$whoami = whoami

#pull from array and add to file
$report = New-Object psobject
#timestamp
$report | Add-Member -MemberType NoteProperty -name Date -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
$report | Add-Member -MemberType NoteProperty -name Serial -Value $BIOS.SerialNumber
$report | Add-Member -MemberType NoteProperty -name AssetNo -Value $assetNo
$report | Add-Member -MemberType NoteProperty -name Company -Value $company
$report | Add-Member -MemberType NoteProperty -name Location -Value $location
$report | Add-Member -MemberType NoteProperty -name Owner -Value $owner
$report | Add-Member -MemberType NoteProperty -name Grouptag -Value $grouptag
#$report | Add-Member -MemberType NoteProperty -name User -Value $ComputerSystem.username
$report | Add-Member -MemberType NoteProperty -name User -Value $whoami
$report | Add-Member -MemberType NoteProperty -name Model -Value $ComputerSystem.Model
$report | Add-Member -MemberType NoteProperty -name SystemFamily -Value $ComputerSystem.SystemFamily
$report | Add-Member -MemberType NoteProperty -name Domain -Value $ComputerSystem.Domain
$report | Add-Member -MemberType NoteProperty -name Description -Value $ComputerSystem.Description
$report | Add-Member -MemberType NoteProperty -name PrimaryOwnerName -Value $ComputerSystem.PrimaryOwnerName
$report | Add-Member -MemberType NoteProperty -name SystemType -Value $ComputerSystem.SystemType
$report | Add-Member -MemberType NoteProperty -name Name -Value $BootConfiguration.Name
$report | Add-Member -MemberType NoteProperty -name ConfigurationPath -Value $BootConfiguration.ConfigurationPath
$report | Add-Member -MemberType NoteProperty -name PSComputerName -Value $BIOS.PSComputerName
$report | Add-Member -MemberType NoteProperty -name Manufacturer -Value $BIOS.Manufacturer
$report | Add-Member -MemberType NoteProperty -name Version -Value $BIOS.Version
$report | Add-Member -MemberType NoteProperty -name Caption -Value $OS.Caption
$report | Add-Member -MemberType NoteProperty -name CSDVersion -Value $OS.CSDVersion
$report | Add-Member -MemberType NoteProperty -name OSArchitecture -Value $OS.OSArchitecture
$report | Add-Member -MemberType NoteProperty -name OSLanguage -Value $OS.OSLanguage

$report | export-csv $OutputFile -NoTypeInformation -append


# output to screen
#$report | Format-Table -AutoSize
# output entire $report object to screen
$report | Format-List *