Connect-AzAccount

# Define Subscription Name
$subscriptionName = "Subscription name"  # Change this to your actual subscription name

# Set output CSV and log paths
$outputCsv = "$PWD\AzureResources.csv"
$logFile = "$PWD\script_log.txt"

# Clear previous log file
Clear-Content -Path $logFile -ErrorAction SilentlyContinue

# Get the subscription ID based on the given name
$subscription = Get-AzSubscription | Where-Object { $_.Name -eq $subscriptionName }

if (-not $subscription) {
    Write-Output "Subscription '$subscriptionName' not found!" | Out-File -FilePath $logFile
    exit
}

# Set subscription context
Set-AzContext -SubscriptionId $subscription.Id | Out-Null
Write-Output "Processing Subscription: $subscriptionName" | Out-File -Append -FilePath $logFile

# Initialize data array
$data = @()
$allTags = @{}

# Get all resources in the subscription
$resources = Get-AzResource | Select-Object ResourceGroupName, Name, ResourceType, ResourceId, Tags

# First pass: Collect all unique tag keys (ignoring empty ones and hidden-link keys)
foreach ($resource in $resources) {
    if ($resource.Tags) {
        foreach ($tag in $resource.Tags.GetEnumerator()) {
            $originalTagKey = $tag.Key.Trim()  # Keep original case and remove extra spaces

            if ($tag.Value -ne $null -and $tag.Value -ne "" -and $originalTagKey -notmatch "(?i)^hidden-link:") {
                $allTags[$originalTagKey] = $true  # Store valid tag keys with original case
            }
        }
    }
}

# Second pass: Process resources and create output rows
foreach ($resource in $resources) {
    $row = [ordered]@{
        "SUBSCRIPTION_NAME"   = $subscriptionName
        "RESOURCE_GROUP_NAME" = $resource.ResourceGroupName
        "RESOURCE_NAME"       = $resource.Name
        "RESOURCE_TYPE"       = $resource.ResourceType
        "RESOURCE_ID"         = $resource.ResourceId
    }

    # Add tag columns dynamically (default empty values)
    foreach ($tagKey in $allTags.Keys) {
        $row[$tagKey] = ""
    }

    # Populate tags for the resource
    if ($resource.Tags) {
        foreach ($tag in $resource.Tags.GetEnumerator()) {
            $originalTagKey = $tag.Key.Trim()

            if ($allTags.ContainsKey($originalTagKey)) {
                $row[$originalTagKey] = $tag.Value  # Assign the correct tag value
            }
        }
    }

    # Convert to PSCustomObject and add to data array
    $data += New-Object PSObject -Property $row
}

# Export data to CSV
$data | Export-Csv -Path $outputCsv -NoTypeInformation -Force
Write-Output "CSV Export Completed: $outputCsv" | Out-File -Append -FilePath $logFile
Write-Output "Completed Subscription: $subscriptionName" | Out-File -Append -FilePath $logFile