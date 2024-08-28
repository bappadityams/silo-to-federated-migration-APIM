# Define your subscriptionId, resourceGroupName, and serviceName  
$siloAPIMsubscriptionId = ""  # Replace with your actual subscriptionId
$siloAPIMresourceGroupName = "rg-apim-ws"  
$siloAPIMserviceName = "apim-silo-001"
$siloAPIMapiVersion = "2023-09-01-preview" 

# Define your subscriptionId, resourceGroupName, and serviceName  
$federatedAPIMsubscriptionId = ""  # Replace with your actual subscriptionId
$federatedAPIMresourceGroupName = "rg-ai-bban"  
$federatedAPIMserviceName = "apim-ws-bban-1"
$federatedAPIMworkspaceId="pricing"  
$federatedAPIMapiVersion = "2023-09-01-preview" 

# Get the access token 
$siloAPIMaccessToken="" # Replace with your actual token
$federatedAPIMaccessToken = ""  # Replace with your actual token



# Define the URL to fetch the list of subscriptions  
$listAllSubscriptionurl = "https://management.azure.com/subscriptions/$siloAPIMsubscriptionId/resourceGroups/$siloAPIMresourceGroupName/providers/Microsoft.ApiManagement/service/$siloAPIMserviceName/subscriptions?api-version=$siloAPIMapiVersion" # Replace with your actual endpoint  

# Invoke the REST API  
$response = Invoke-RestMethod -Method Get -Uri $listAllSubscriptionurl -Headers @{Authorization="Bearer $siloAPIMaccessToken"} -ContentType "application/json"  

Write-Output $response 
  
# Parse the response and loop through each subscription  
foreach($subscription in $response.value){  
  $subscriptionName = $subscription.name
  $subscriptionId = (New-Guid).ToString()  
  $scopePath = $subscription.properties[0].scope
  
  $scopeName = ($scopePath -split '/')[($scopePath -split '/').Count - 1]  
 if ($scopeName -eq "apis"){  
    $scopeName = "apis"  
  }
  else{  
    $scopeName = ($scopePath -split '/')[($scopePath -split '/').Count - 2] +"/"+ ($scopePath -split '/')[($scopePath -split '/').Count - 1]
  }

  Write-Output $scopeName  
  $ownerId = $subscription.properties[0].ownerId -split '/' | Select-Object -Last 1 
 
  #call the REST API to get the keys
  $keyUrl = "https://management.azure.com/subscriptions/$siloAPIMsubscriptionId/resourceGroups/$siloAPIMresourceGroupName/providers/Microsoft.ApiManagement/service/$siloAPIMserviceName/subscriptions/$($subscriptionName)/listSecrets?api-version=$siloAPIMapiVersion" # Replace with your actual endpoint

  $keys = Invoke-RestMethod -Method Post -Uri $keyUrl -Headers @{Authorization="Bearer $siloAPIMaccessToken"} -ContentType "application/json"



# Define the base URL for the API request  
$federatedAPIMImportSubUrl = "https://management.azure.com/subscriptions/$federatedAPIMsubscriptionId/resourceGroups/$federatedAPIMresourceGroupName/providers/Microsoft.ApiManagement/service/$federatedAPIMserviceName/workspaces/$federatedAPIMworkspaceId/subscriptions/$($subscriptionId)?api-version=$federatedAPIMapiVersion"  

$properties = @{  
        scope       = "/subscriptions/$federatedAPIMsubscriptionId/resourceGroups/$federatedAPIMresourceGroupName/providers/Microsoft.ApiManagement/service/$federatedAPIMserviceName/workspaces/$federatedAPIMworkspaceId/$($scopeName)"  
        displayName = $subscriptionName  
        primaryKey  = $keys.primaryKey  
        secondaryKey = $keys.secondaryKey  
    }

# Check if ownerId exists and is not null or empty  
if ($null -ne $ownerId -and $ownerId -ne '') {  
    $properties.ownerId = "/subscriptions/$federatedAPIMsubscriptionId/resourceGroups/$federatedAPIMresourceGroupName/providers/Microsoft.ApiManagement/service/$federatedAPIMserviceName/users/$($ownerId)"  
}  
  
$body = @{  
    properties = $properties  
} | ConvertTo-Json  

   # Invoke the REST API  
   Invoke-RestMethod -Method Put -Uri $federatedAPIMImportSubUrl -Body $body -Headers @{Authorization="Bearer $federatedAPIMaccessToken"} -ContentType "application/json"  
}