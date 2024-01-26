#Set the target subscription
Set-AzContext -Subscription 'subscriptionID'
# Define the tag values
# For Linux it can be changed to $linuxOSTag and os_version = SLES 15 SP4 for instance
$windowsOSTag = @{ os_version = "Windows Server 2016 Datacenter" } 

# Get the virtual machines
$vms = Get-AzVM

foreach ($vm in $vms) {
    $tags = @{}

    # Check if the operating system is Windows / or Linux if you replace the "Windows" with "Linux" 
    if ($vm.StorageProfile.OsDisk.OsType -eq "Windows") {
        $tags += $windowsOSTag
    }

    # Apply the tags to the virtual machine
    if ($tags.Count -gt 0) {
        $vmTags = $vm.Tags
        $vmTags += $tags
        Set-AzResource -ResourceId $vm.Id -Tag $vmTags -Force
        Write-Host "Tags applied to VM: $($vm.Name)"
    }
}
