# tf-azure-tests

This repository contains Terraform experiments conducted to investigate and reproduce the issue reported in [terraform-provider-mysql #240](https://github.com/petoju/terraform-provider-mysql/issues/240).

## Overview

The testing focused on Azure MySQL Flexible Server integration with Azure Active Directory (AAD) authentication using the petoju/mysql Terraform provider, specifically examining behavior differences between provider versions.

## Initial Resource Creation

### Setup Process

1. **Azure Infrastructure**: Created necessary Azure resources for MySQL Flexible Server
2. **MySQL Provider Testing**: Used petoju/mysql provider version 3.0.76 to create MySQL users with `aad_auth` plugin
3. **Initial Results**: All operations worked as expected

### User Authentication Results

After initial setup with provider version 3.0.76, the following users were successfully created:

```
user                            |host     |authentication_string                                                                                        |
--------------------------------+---------+-------------------------------------------------------------------------------------------------------------+
anotheruser@ytamang48outlook.onm|%        |AADUser:609779f8-d689-4f10-a1ba-ac47afdcdbef:upn:609779f8-d689-4f10-a1ba-ac47afdcdbef                        |
pluralsight                     |%        |*E9203D40C046938F74FC4B09F30F0D3C1ADD46A0                                                                    |
tf-mysql-mysql-users            |%        |AADGroup:8746059f-7da3-40c3-a15a-0ad11eb5314e:upn:tf-mysql-mysql-users                                       |
umi-7ada7a38                    |%        |AADSP:f0ede8f4-77ba-41ba-bef3-1217ae554c60:upn:umi-7ada7a38                                                  |
```

## Provider Version Testing

### Version 3.0.78 Testing

- **Upgrade**: Updated provider from 3.0.76 to 3.0.78
- **Issue Reproduction**: Unable to replicate the issue reported by __mdimiceli-saas__
- **User Modification**: Successfully modified existing users with `aad_auth` plugin
- **Result**: Version 3.0.78 worked as expected in this environment

## Useful Commands

### Environment Setup

```bash
# Set Azure subscription
export ARM_SUBSCRIPTION_ID=""

# Get access token for MySQL
ACCESS_TOKEN=$(az account get-access-token --resource https://ossrdbms-aad.database.windows.net | jq -r .accessToken)
```

### Azure AD Operations

```bash
# Get user information
az ad user show --id cloud_user_p_1003bdc9@realhandsonlabs.com  

# List accounts
az account list

# Create new AD user
az ad user create --display-name myuser --password password --user-principal-name myuser@ytamang48outlook.onmicrosoft.com
```

### Azure Provider Registration

```bash
# Register required providers
az provider register --namespace Microsoft.ManagedIdentity
az provider register --namespace Microsoft.DBforMySQL

# Check registration status
az provider show --namespace Microsoft.DBforMySQL --query "registrationState"
```

## Troubleshooting
### Permission Issues
If you encounter permission-related issues during setup or testing, use the provided fix-roles.sh script to resolve role assignment problems.
```bash
bash./fix-roles.sh
```

## Conclusion

The testing environment successfully demonstrated the functionality of both provider versions (3.0.76 and 3.0.78) with Azure MySQL Flexible Server and AAD authentication. The specific issue reported in the GitHub issue could not be reproduced in this setup.