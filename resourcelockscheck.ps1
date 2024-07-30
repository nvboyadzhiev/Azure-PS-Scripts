[string]$lockName = "sub-all-CD-Lock"
[string]$subscriptionId = "fee3cf06-c174-449d-adcb-8caaca0250e0"
[string]$lockLevel = "CanNotDelete" # or "ReadOnly"


Write-Output "SubscriptionId: $subscriptionId"
Write-Output "LockName: $lockName"
Write-Output "LockLevel: $lockLevel"

if (-not $subscriptionId) {
    Write-Error "SubscriptionId cannot be null or empty."
    exit
}

if (-not $lockName) {
    Write-Error "LockName cannot be null or empty."
    exit
}

if ($lockLevel -notin @("CanNotDelete", "ReadOnly")) {
    Write-Error "Invalid LockLevel. Valid values are 'CanNotDelete' or 'ReadOnly'."
    exit
}

try {
    Connect-AzAccount -Identity -ErrorAction Stop
    Write-Output "Authenticated successfully with Managed Identity."
} catch {
    Write-Error "Failed to authenticate with Azure using Managed Identity. Ensure the Managed Identity has appropriate permissions."
    exit
}


$scope = "/subscriptions/$subscriptionId"

# Check if the lock exists
try {
    $lock = Get-AzResourceLock -Scope $scope -ErrorAction SilentlyContinue | Where-Object {$_.Name -eq $lockName}

    if (-not $lock) {
        # Re-apply the lock if it doesn't exist
        # Force application to avoid any prompts
        New-AzResourceLock -LockName $lockName -LockLevel $lockLevel -Scope $scope -Force | Out-Null
        Write-Output "Lock '$lockName' of level '$lockLevel' has been applied to subscription '$subscriptionId'."
    } else {
        Write-Output "Lock '$lockName' already exists on subscription '$subscriptionId'."
    }
} catch {
    Write-Error "An error occurred while managing resource locks: $_"
}
