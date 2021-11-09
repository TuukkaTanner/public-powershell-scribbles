# Intune Device display name Configuration script
# Close down Powershell to connect to a new customer tenant
# Compiled by Tuukka Tanner

#Defines  the required module variables
$AP_module = "WindowsAutoPilotIntune"
$Intune_module = "Microsoft.Graph.Intune"

#Installs the required module if missing (AutoPilot)
if (Get-Module -ListAvailable -Name $AP_module) {
    Write-Host "Module $AP_module exists"
} 
else {
    Write-Host "Module $AP_module does not exist"
    Write-Host "Installing module $AP_module"
    Install-Module $AP_module

}

#Installs the required Module if missing (Graph.Intune)
if (Get-Module -ListAvailable -Name $Intune_module) {
    Write-Host "Module $Intune_module exists"
} 
else {
    Write-Host "Module $Intune_module does not exist"
    Write-Host "Installing module $Intune_module"
    Install-Module $Intune_module

}

#Imports the required modules (Graph.Intune and AutoPilotIntune)
Import-Module $AP_module
Import-module $Intune_module


#Connects to MSGraph api
Connect-MSGraph | Out-Null

# Loops through the Device list and looks for any devices that are still in any other state than "Assigned"
# This is to wait for the assignment of the profile
# The device names are not synced if the status is anything other than "Assigned"
        
        Write-Host "Waits for all of the devices to be synced properly to AutoPilot with Assigned status..."
        $processingCount = 1
        while ($processingCount -gt 0)
        {
            $deviceStatuses = @(Get-AutopilotDevice | Select-Object serialNumber,deploymentProfileAssignmentStatus)
            $deviceCount = $deviceStatuses.Length

            # Check to see if any devices are still processing
            $processingCount = 0
            foreach ($device in $deviceStatuses){
                if ($device.deploymentProfileAssignmentStatus -notlike "assigned*") {
                    $processingCount = $processingCount + 1
                }
            }
            Write-Host "Waiting for $processingCount of $deviceCount devices"

            # Still processing? Sleep before trying again.
            if ($processingCount -gt 0){
                Start-Sleep 60
            }
        }

        # Display the statuses
        $deviceStatuses | ForEach-Object {
            Write-Host "Device: $($_.serialNumber) Profile Status: $($_.deploymentprofileassignmentstatus)"
        }

        # Read the CSV and process each device for an extra "Display Name" field to update the Device Name to the UI side
        # This way you can use a single .csv for import and naming the devices uniquely.
        # Variables are different just for safety, running this with the same foreach loop as listed above would've been enough
        Write-Host "Please Provide the AutoPilot CSV file with added 'Display Name' -column added"
        Write-Host "Also do note, that you have to check the existing device names with a different script for the last running number"
        $csvFile = Read-Host -Prompt "Please provide the CSV Path" 
        Write-Host "Renaming devices..."
        $device_displaynames = Import-CSV $csvFile
        foreach ($device_displayname in $device_displaynames) {
            if ($null -ne $device_displayname.'Display Name'){
                $id_for_renaming = get-autopilotdevice -serial $device_displayname.'Device Serial Number' | Select-Object -ExpandProperty ID
                Set-AutopilotDevice -id $id_for_renaming -displayName $device_displayname.'Display Name'
            } 
            else {
                
            }   

        }
        foreach ($device_displayname in $device_displaynames) {
            $renamed_devices = get-autopilotdevice -serial $device_displayname.'Device Serial Number' | Select-Object ID, serialNumber
            Write-Host "Renaming Completed for: $renamed_Devices"
        }
    

        Start-Sleep -Seconds 3
        Write-host ""
        Write-Host "As an additional option:"
        Write-host "Do you want to fetch the data for all of the current device names via Powershell?"
        Write-Host "Do note, that these results require the Module 'Invoke-AutopilotSync to run correctly before data is displayed."
        $datafetch = Read-Host "If you do, please enter 'y' to show the results"
                
        if ($datafetch -eq 'y'){
                #Gets the device info to Powershell
                $AutoPilotDeviceList = get-autopilotdevice -expand | Select-Object Displayname, serialnumber, id, model  | Sort-Object -property "displayname"
                $AutoPilotDeviceList | Out-GridView
        }