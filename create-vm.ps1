{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",

  "parameters": {
    "vmName": {
      "type": "string",
      "metadata": {
        "description": "Virtual Machine Name"
      }
    },
    "adminPassword": {
      "type": "secureString",
      "metadata": {
        "description": "Administrator Password"
      }
    },
    "location": {
      "type": "string",
      "metadata": {
        "description": "Resource location"
      }
    },
    "vnetAddressSpace": {
      "type": "string",
      "metadata": {
        "description": "VNet address space (Example: 10.0.0.0/16)"
      }
    },
    "subnetAddressPrefix": {
      "type": "string",
      "metadata": {
        "description": "Subnet address prefix (Example: 10.0.1.0/24)"
      }
    }
  },

  "variables": {
    "location": "[parameters('location')]",
    "adminUsername": "abychen",
    "vmSize": "Standard_D2s_v3",

    "vnetName": "[concat(parameters('vmName'),'-vnet')]",
    "subnetName": "[concat(parameters('vmName'),'-snet')]",

    "publicIpName": "[concat(parameters('vmName'),'-ip')]",
    "nsgName": "[concat(parameters('vmName'),'-nsg')]",
    "nicName": "[concat(parameters('vmName'),'-nic')]",

    "computerName": "[take(parameters('vmName'),15)]"
  },

  "resources": [
    {
      "type": "Microsoft.Network/publicIPAddresses",
      "apiVersion": "2023-06-01",
      "name": "[variables('publicIpName')]",
      "location": "[variables('location')]",
      "sku": {
        "name": "Standard"
      },
      "properties": {
        "publicIPAllocationMethod": "Static"
      }
    },

    {
      "type": "Microsoft.Network/networkSecurityGroups",
      "apiVersion": "2023-09-01",
      "name": "[variables('nsgName')]",
      "location": "[variables('location')]",
      "properties": {
        "securityRules": [
          {
            "name": "RDP",
            "properties": {
              "priority": 300,
              "protocol": "Tcp",
              "access": "Allow",
              "direction": "Inbound",
              "sourceAddressPrefix": "*",
              "sourcePortRange": "*",
              "destinationAddressPrefix": "*",
              "destinationPortRange": "3389"
            }
          }
        ]
      }
    },

    {
      "type": "Microsoft.Network/virtualNetworks",
      "apiVersion": "2024-01-01",
      "name": "[variables('vnetName')]",
      "location": "[variables('location')]",
      "properties": {
        "addressSpace": {
          "addressPrefixes": [
            "[parameters('vnetAddressSpace')]"
          ]
        },
        "subnets": [
          {
            "name": "[variables('subnetName')]",
            "properties": {
              "addressPrefix": "[parameters('subnetAddressPrefix')]"
            }
          }
        ]
      }
    },

    {
      "type": "Microsoft.Network/networkInterfaces",
      "apiVersion": "2022-11-01",
      "name": "[variables('nicName')]",
      "location": "[variables('location')]",
      "dependsOn": [
        "[resourceId('Microsoft.Network/publicIPAddresses', variables('publicIpName'))]",
        "[resourceId('Microsoft.Network/networkSecurityGroups', variables('nsgName'))]",
        "[resourceId('Microsoft.Network/virtualNetworks', variables('vnetName'))]"
      ],
      "properties": {
        "enableAcceleratedNetworking": false,
        "networkSecurityGroup": {
          "id": "[resourceId('Microsoft.Network/networkSecurityGroups', variables('nsgName'))]"
        },
        "ipConfigurations": [
          {
            "name": "ipconfig1",
            "properties": {
              "privateIPAllocationMethod": "Dynamic",
              "publicIPAddress": {
                "id": "[resourceId('Microsoft.Network/publicIPAddresses', variables('publicIpName'))]"
              },
              "subnet": {
                "id": "[resourceId('Microsoft.Network/virtualNetworks/subnets', variables('vnetName'), variables('subnetName'))]"
              }
            }
          }
        ]
      }
    },

    {
      "type": "Microsoft.Compute/virtualMachines",
      "apiVersion": "2024-03-01",
      "name": "[parameters('vmName')]",
      "location": "[variables('location')]",
      "dependsOn": [
        "[resourceId('Microsoft.Network/networkInterfaces', variables('nicName'))]"
      ],
      "properties": {
        "hardwareProfile": {
          "vmSize": "[variables('vmSize')]"
        },

        "storageProfile": {
          "imageReference": {
            "publisher": "MicrosoftWindowsDesktop",
            "offer": "Windows-10",
            "sku": "win10-22h2-ent-g2",
            "version": "latest"
          },
          "osDisk": {
            "createOption": "FromImage",
            "deleteOption": "Delete",
            "managedDisk": {
              "storageAccountType": "Premium_LRS"
            }
          }
        },

        "osProfile": {
          "computerName": "[variables('computerName')]",
          "adminUsername": "[variables('adminUsername')]",
          "adminPassword": "[parameters('adminPassword')]"
        },

        "networkProfile": {
          "networkInterfaces": [
            {
              "id": "[resourceId('Microsoft.Network/networkInterfaces', variables('nicName'))]"
            }
          ]
        },

        "securityProfile": {
          "securityType": "TrustedLaunch",
          "uefiSettings": {
            "secureBootEnabled": true,
            "vTpmEnabled": true
          }
        },

        "diagnosticsProfile": {
          "bootDiagnostics": {
            "enabled": true
          }
        },

        "licenseType": "Windows_Client",

        "additionalCapabilities": {
          "hibernationEnabled": false
        }
      }
    }
  ],

  "outputs": {
    "vmName": {
      "type": "string",
      "value": "[parameters('vmName')]"
    },
    "publicIpName": {
      "type": "string",
      "value": "[variables('publicIpName')]"
    },
    "vnetAddressSpace": {
      "type": "string",
      "value": "[parameters('vnetAddressSpace')]"
    },
    "subnetAddressPrefix": {
      "type": "string",
      "value": "[parameters('subnetAddressPrefix')]"
    }
  }
}