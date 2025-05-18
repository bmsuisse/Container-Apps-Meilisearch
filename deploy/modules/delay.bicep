// delay.bicep - A helper module to introduce delays in ARM deployments
@description('The duration of the delay in seconds (default is 30 seconds)')
param delayInSeconds int = 30

var deploymentNameGuid = guid(deployment().name)

// Use script module to create a delay
resource delayScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'delay-script-${take(deploymentNameGuid, 5)}'
  location: resourceGroup().location
  kind: 'AzurePowerShell'
  properties: {
    azPowerShellVersion: '7.0'
    retentionInterval: 'PT1H'
    timeout: 'PT${delayInSeconds}S'
    cleanupPreference: 'Always'
    scriptContent: 'Start-Sleep -Seconds ${delayInSeconds}; Write-Output "Delay completed after ${delayInSeconds} seconds."'
  }
}

// No meaningful outputs
output delayComplete bool = true
