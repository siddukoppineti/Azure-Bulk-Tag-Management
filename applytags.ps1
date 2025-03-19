Connect-AzAccount

# Define input and output files
$inputCsv = "$PWD\AzureResources.csv"  # Input CSV with updated tags
$logCsv = "$PWD\Tag_Update_Log.csv"    # Output log CSV

# Check if the input CSV exists and is not empty
if (!(Test-Path $inputCsv) -or ((Get-Item $inputCsv).Length -eq 0)) {
    Write-Output "Error: CSV file is empty or not found!"
    exit
}

# Read CSV data
$data = Import-Csv -Path $inputCsv -Encoding UTF8

# Ensure data is not empty after import
if (-not $data) {
    Write-Output "Error: CSV contains no data!"
    exit
}

# Initialize log data array
$logData = @()

# Iterate over each row in the CSV
foreach ($row in $data) {
    $resourceId = $row.RESOURCE_ID.Trim()
    if (-not $resourceId) { continue }  # Skip empty rows

    $existingResource = Get-AzResource -ResourceId $resourceId -ErrorAction SilentlyContinue
    if (-not $existingResource) {
        Write-Output "Warning: Resource ID $resourceId not found. Skipping..."
        continue
    }

    # Get existing tags, ensuring it's a hashtable
    $existingTags = @{}
    if ($existingResource.Tags) {
        $existingTags = @{} + $existingResource.Tags
    }

    $updatedTags = @{}
    $tagsToDelete = @{}
    $hasChanges = $false

    # Iterate over all columns (excluding metadata columns)
    foreach ($column in $row.PSObject.Properties.Name) {
        if ($column -in @("SUBSCRIPTION_NAME", "RESOURCE_GROUP_NAME", "RESOURCE_NAME", "RESOURCE_TYPE", "RESOURCE_ID")) {
            continue  # Skip metadata columns
        }

        $newValue = $row.$column.Trim()
        $existingValue = if ($existingTags.ContainsKey($column)) { $existingTags[$column] } else { $null }

        # Skip if the value is empty or already exists (no changes needed)
        if ([string]::IsNullOrWhiteSpace($newValue) -or $newValue -eq $existingValue) {
            continue
        }

        # Remove tag if value is "DELETE"
        if ($newValue -eq "DELETE") {
            if ($existingTags.ContainsKey($column)) {
                $tagsToDelete[$column] = $null  # Mark tag for removal
                $hasChanges = $true
                $logData += [PSCustomObject]@{
                    "Resource_ID"  = $resourceId
                    "Tag"          = $column
                    "Old_Value"    = $existingValue
                    "New_Value"    = "DELETED"
                    "Action"       = "Tag Deleted"
                    "Timestamp"    = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                }
            }
        } else {
            $updatedTags[$column] = $newValue
            $hasChanges = $true
            $logData += [PSCustomObject]@{
                "Resource_ID"  = $resourceId
                "Tag"          = $column
                "Old_Value"    = $existingValue
                "New_Value"    = $newValue
                "Action"       = "Tag Updated"
                "Timestamp"    = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            }
        }
    }

    # Apply tag updates if any exist
    if ($hasChanges) {
        # Step 1: Remove tags marked for deletion
        if ($tagsToDelete.Count -gt 0) {
            Update-AzTag -ResourceId $resourceId -Operation Delete -Tag $tagsToDelete -ErrorAction SilentlyContinue
            Write-Output "Deleted tags: $($tagsToDelete.Keys -join ', ') for resource: $resourceId"
        }

        # Step 2: Apply tag updates if any remain
        if ($updatedTags.Count -gt 0) {
            Update-AzTag -ResourceId $resourceId -Operation Merge -Tag $updatedTags
            Write-Output "Updated tags for resource: $resourceId"
        }
    }
}

# Export log data
if ($logData.Count -gt 0) {
    $logData | Export-Csv -Path $logCsv -NoTypeInformation -Force
    Write-Output "Tag updates logged to: $logCsv"
} else {
    Write-Output "No tag changes detected."
}
