# Azure-Bulk-Tag-Management
This repository provides the PowerShell scripts for azure bulk tag management


Overview

This PowerShell automation consists of two scripts:

Discovery Script – Scans Azure resources and generates a CSV file listing all resources, including their tags(AzureResources.csv).

Bulk Tagging Script – Reads a predefined CSV (AzureResources.csv) and applies tag changes (addition, modification, or deletion) in bulk.


Prerequisites:

PowerShell 7+

Azure PowerShell Module (Install-Module -Name Az -AllowClobber)

Required permissions to list and manage Azure resources.

CSV files:
AzureResources.csv (generated by the discovery script)



Step 1: Discovery Script

Purpose:

The discovery script scans the Azure subscription provided in the script(Subscription ), collects information on resources, and exports it to a CSV file.
script - resource.ps1(available in the repo)
run cmd - .\resourecs.ps1


Step 2: Adding tags to the generated file

We can add a new tag in new column, or modify the existing tag
If TagValue is DELETE, the script removes that tag.
Otherwise, it adds or updates the tag.


Step 3: Bulk Tagging Script

Purpose:
This script reads the AzureResource.csv file and applies tag updates to Azure resources in bulk.
script - applytags.ps1(available in the repo)
run cmd - .\applytags.ps1



How It Works:

Check for Input CSV:

Ensure the input file (AzureResources.csv) exists and isn’t empty. If it’s missing or empty, stop the script.


Read the CSV File:

Load the data from the CSV to get updated tag information.


Check Each Resource:

For each resource in the CSV:

Check if the resource exists in Azure.

Skip any resources that don't exist.


Compare Tags:

Compare the current tags on the resource with the new tags from the CSV.

If the tag needs to be updated or deleted, record the change.


Apply Changes:

Update the tags if they’ve changed.

If a tag is marked for deletion, remove it.


Log Changes:

Log every update or deletion in a separate file (Tag_Update_Log.csv) with details about what was changed, including resource ID, tag name, old and new values, and the timestamp.


Finish:

Once all resources are processed, export the change log to the output CSV file.



Key Features:

✅ Supports bulk tagging across multiple subscriptions

✅ Handles tag creation, modification, and deletion 

✅ Logs every operation with success or failure messages
