## tf-azure-tests
This repository contains my terraform experiments after issue was raised here: https://github.com/petoju/terraform-provider-mysql/issues/240
## Initial resource creations
- I initially created azure related resources. Then used petoku/mysql provider version 3.0.76 to create mysql users with aad_auth plugin.
- Everything worked as expected. 
```
user                            |host     |authentication_string                                                                                        |
--------------------------------+---------+-------------------------------------------------------------------------------------------------------------+
anotheruser@ytamang48outlook.onm|%        |AADUser:609779f8-d689-4f10-a1ba-ac47afdcdbef:upn:609779f8-d689-4f10-a1ba-ac47afdcdbef                        |
pluralsight                     |%        |*E9203D40C046938F74FC4B09F30F0D3C1ADD46A0                                                                    |
tf-mysql-mysql-users            |%        |AADGroup:8746059f-7da3-40c3-a15a-0ad11eb5314e:upn:tf-mysql-mysql-users                                       |
umi-7ada7a38                    |%        |AADSP:f0ede8f4-77ba-41ba-bef3-1217ae554c60:upn:umi-7ada7a38                                                  |
```
- After this I upgraded provider to 3.0.78 but I was not able to replicate the issue mdimiceli-saas faced. 
- Additionally, I also changed user of those using aad_auth plugin but version 3.0.78 worked as expected.
## Useful commands
```sh
export ARM_SUBSCRIPTION_ID=""
ACCESS_TOKEN=$(az account get-access-token --resource https://ossrdbms-aad.database.windows.net | jq -r .accessToken)
az ad user show --id cloud_user_p_1003bdc9@realhandsonlabs.com  
az account list

az ad user create --display-name myuser --password password --user-principal-name myuser@ytamang48outlook.onmicrosoft.com
az provider register --namespace Microsoft.ManagedIdentity
az provider register --namespace Microsoft.DBforMySQL
az provider show --namespace Microsoft.DBforMySQL --query "registrationState"
```