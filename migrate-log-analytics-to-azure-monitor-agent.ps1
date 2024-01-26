$extensionName = "AzureMonitorWindowsAgent"
$extensionPublisher = "Microsoft.Azure.Monitoring.VMDiagnosticsSettings"
$workspaceResourceGroupName = "rg-sapdev"  # Replace with the actual resource group name of the Log Analytics workspace
$workspaceName = "LAW-SAPDEVUKS"

# Retrieve the Log Analytics workspace in the specified resource group
$workspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $workspaceResourceGroupName -Name $workspaceName

# Get all resource groups
$resourceGroups = Get-AzResourceGroup

foreach ($resourceGroup in $resourceGroups) {
    $resourceGroupName = $resourceGroup.ResourceGroupName

    # Exclude the Log Analytics workspace resource group from the VM search
    if ($resourceGroupName -eq $workspaceResourceGroupName) {
        continue
    }

    # Get all VMs in the current resource group
    $vms = Get-AzVM -ResourceGroupName $resourceGroupName

    foreach ($vm in $vms) {
        $vmName = $vm.Name

        # Exclude VMs that start with "azl"
        if ($vmName -like "azl*") {
            continue
        }

        # Check if the Azure Monitor Windows agent extension is already installed on the VM
        $extension = Get-AzVMExtension -ResourceGroupName $resourceGroupName -VMName $vmName -Name $extensionName -ErrorAction SilentlyContinue

        if ($extension -ne $null) {
            Write-Host "Azure Monitor Windows agent extension already installed on VM: $vmName in resource group: $resourceGroupName"
        } else {
            # Retrieve the VM's current Log Analytics workspace ID
            $workspaceId = $workspace.CustomerId

            if ($workspaceId -ne $null) {
                $workspaceKey = (Get-AzOperationalInsightsWorkspaceSharedKeys -ResourceGroupName $workspaceResourceGroupName -Name $workspaceName).PrimarySharedKey

                if ($workspaceKey -ne $null) {
                    # Remove the existing Log Analytics agent from the VM
                    Remove-AzVMExtension -ResourceGroupName $resourceGroupName -VMName $vmName -Name $extensionName

                    # Install the Azure Monitor Windows agent extension on the VM
                    Set-AzVMExtension -ResourceGroupName $resourceGroupName -VMName $vmName -Name $extensionName -Publisher $extensionPublisher -TypeHandlerVersion "1.5" -ExtensionType "IaaSDiagnostics" -ForceRerun -Settings @{workspaceId=$workspaceId; workspaceKey=$workspaceKey}

                    Write-Host "Azure Monitor Windows agent installed on VM: $vmName in resource group: $resourceGroupName"
                } else {
                    Write-Host "Unable to retrieve Log Analytics workspace shared key for VM: $vmName in resource group: $resourceGroupName"
                }
            } else {
                Write-Host "Unable to retrieve Log Analytics workspace ID for VM: $vmName in resource group: $resourceGroupName"
            }
        }
    }
}

Write-Host "Migration complete."
