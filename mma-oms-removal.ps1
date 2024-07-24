# Path to the CSV file
$csvFilePath = "C:\Users\xxxx\subscriptions.csv"

# Read the CSV file
try {
    $subscriptions = Import-Csv -Path $csvFilePath -ErrorAction Stop
} catch {
    Write-Error "Failed to read the CSV file:"
    exit 1
}

# Iterate through each subscription in the CSV file
foreach ($subscription in $subscriptions) {
    $SubscriptionName = $subscription.Subscription
    $SubscriptionId = $subscription.SubscriptionId
    $ResourceGroupName = $subscription.ResourceGroupName  # Get the ResourceGroupName from the CSV

    try {
        # Set the current subscription context
        Set-AzContext -SubscriptionId $subscriptionId -ErrorAction Stop
    } catch {
        Write-Error "Failed to set subscription context for subscription '$subscriptionName'"
        continue
    }

    try {
        # Get all VMs in the current subscription
        $vms = Get-AzVM -ResourceGroupName $ResourceGroupName -ErrorAction Stop
    } catch {
        Write-Error "Failed to retrieve VMs for subscription '$SubscriptionName'"
        continue
    }

    # Iterate through each VM
    foreach ($vm in $vms) {
        $VMName = $vm.Name
        Write-Output "Checking VM: $VMName"

        # Check if the AMA or MMA or OMS extension is installed on the VM
        try {
            $mmaExtension = Get-AzVMExtension -ResourceGroupName $ResourceGroupName -VMName $VMName -Name "MicrosoftMonitoringAgent" -ErrorAction SilentlyContinue
            $omsExtension = Get-AzVMExtension -ResourceGroupName $ResourceGroupName -VMName $VMName -Name "OmsAgentForLinux" -ErrorAction SilentlyContinue
            $amaWindowsextension = Get-AzVMExtension -ResourceGroupName $ResourceGroupName -VMName $VMName -Name "AzureMonitorWindowsAgent" -ErrorAction SilentlyContinue
            $amaLinuxextension = Get-AzVMExtension -ResourceGroupName $ResourceGroupName -VMName $VMName -Name "AzureMonitorLinuxAgent" -ErrorAction SilentlyContinue
        
            if ($mmaExtension -ne $null -and $amaWindowsextension -ne $null) {
                Write-Output "MMA and AMA extension found on VM: $VMName"

                # Remove the MMA or OMS extension from the VM
                try {
                    Write-Output "Removing MMA/OMS extension from VM: $vmName"
                    Remove-AzVMExtension -ResourceGroupName $ResourceGroupName -VMName $VMName -Name "MicrosoftMonitoringAgent" -Force -ErrorAction Stop
                }
            
                catch {
                    Write-Output "Failed to remove MMA extension from VM '$VMName'"
                    continue
                }
                else {
                    Write-Output "MMA and AMA not found on VM: $VMName"
                }
            } 
            elseif ($omsExtension -ne $null -and $amaLinuxextension -ne $null) {
                Write-Output "OMS and AMA extension found on VM: $VMName"

                # Remove the OMS extension from the VM
                try {
                    Write-Output "Removing MMA/OMS extension from VM: $VMName"
                    Remove-AzVMExtension -ResourceGroupName $ResourceGroupName -VMName $VMName -Name "OmsAgentForLinux" -Force -ErrorAction Stop
                } 
                catch {
                    Write-Output "Failed to remove OMS extension from VM '$VMName'"
                    continue
                }
            }
            else {
                Write-Output "MMA and OMS extension not found on VM: $VMName"
            }
        }
        
        catch {
            Write-Output "Failed to check extensions for VM '$VMName'"
            continue
        }
    }
}
