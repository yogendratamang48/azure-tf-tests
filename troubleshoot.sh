#!/bin/bash

UMI_PRINCIPAL_ID=$(terraform output -json | jq -r '.user_managed_identity.value.principal_id')

echo "=== Assigning Directory Readers Role to UMI ==="
echo "UMI Principal ID: $UMI_PRINCIPAL_ID"
echo ""

# Step 1: Check if UMI already has Directory Readers role
echo "1. Checking if UMI already has Directory Readers role..."
EXISTING_ROLE=$(az rest \
  --method GET \
  --uri "https://graph.microsoft.com/v1.0/servicePrincipals/$UMI_PRINCIPAL_ID/memberOf" \
  --query "value[?displayName=='Directory Readers'].displayName" \
  -o tsv 2>/dev/null)

if [ -n "$EXISTING_ROLE" ]; then
  echo "   ✓ UMI already has Directory Readers role"
  exit 0
fi

echo "   Directory Readers role not found, proceeding with assignment..."

# Step 2: Get Directory Readers role ID
echo ""
echo "2. Getting Directory Readers role ID..."
DIR_READERS_ROLE_ID=$(az rest \
  --method GET \
  --uri "https://graph.microsoft.com/v1.0/directoryRoles" \
  --query "value[?displayName=='Directory Readers'].id" \
  -o tsv 2>/dev/null)

if [ -z "$DIR_READERS_ROLE_ID" ]; then
  echo "   Directory Readers role not active, activating it..."
  
  # Get role template ID
  ROLE_TEMPLATE_ID=$(az rest \
    --method GET \
    --uri "https://graph.microsoft.com/v1.0/directoryRoleTemplates" \
    --query "value[?displayName=='Directory Readers'].id" \
    -o tsv 2>/dev/null)
  
  if [ -z "$ROLE_TEMPLATE_ID" ]; then
    echo "   ❌ Could not find Directory Readers role template"
    exit 1
  fi
  
  echo "   Role template ID: $ROLE_TEMPLATE_ID"
  echo "   Activating Directory Readers role..."
  
  # Activate the role
  ACTIVATION_RESULT=$(az rest \
    --method POST \
    --uri "https://graph.microsoft.com/v1.0/directoryRoles" \
    --headers "Content-Type=application/json" \
    --body "{\"roleTemplateId\": \"$ROLE_TEMPLATE_ID\"}" 2>/dev/null)
  
  if [ $? -eq 0 ]; then
    echo "   ✓ Directory Readers role activated"
    sleep 10  # Wait for activation to propagate
    
    # Get the role ID again
    DIR_READERS_ROLE_ID=$(az rest \
      --method GET \
      --uri "https://graph.microsoft.com/v1.0/directoryRoles" \
      --query "value[?displayName=='Directory Readers'].id" \
      -o tsv 2>/dev/null)
  else
    echo "   ❌ Failed to activate Directory Readers role"
    exit 1
  fi
fi

echo "   Directory Readers role ID: $DIR_READERS_ROLE_ID"

# Step 3: Add UMI to Directory Readers role
echo ""
echo "3. Adding UMI to Directory Readers role..."

ADD_RESULT=$(az rest \
  --method POST \
  --uri "https://graph.microsoft.com/v1.0/directoryRoles/$DIR_READERS_ROLE_ID/members/\$ref" \
  --headers "Content-Type=application/json" \
  --body "{\"@odata.id\": \"https://graph.microsoft.com/v1.0/servicePrincipals/$UMI_PRINCIPAL_ID\"}" 2>&1)

if [ $? -eq 0 ]; then
  echo "   ✓ Successfully added UMI to Directory Readers role"
else
  echo "   Result: $ADD_RESULT"
  if echo "$ADD_RESULT" | grep -q "already exists"; then
    echo "   ✓ UMI already a member of Directory Readers role"
  else
    echo "   ❌ Failed to add UMI to Directory Readers role"
    echo "   Error: $ADD_RESULT"
    
    # Show manual steps
    echo ""
    echo "   MANUAL STEPS REQUIRED:"
    echo "   1. Go to: https://portal.azure.com"
    echo "   2. Navigate to: Azure Active Directory → Roles and administrators"
    echo "   3. Find and click: Directory Readers"
    echo "   4. Click: + Add assignments"
    echo "   5. Search for: $UMI_PRINCIPAL_ID"
    echo "   6. Select and assign"
    exit 1
  fi
fi

# Step 4: Verify assignment
echo ""
echo "4. Verifying assignment..."
sleep 5  # Wait for propagation

VERIFICATION=$(az rest \
  --method GET \
  --uri "https://graph.microsoft.com/v1.0/servicePrincipals/$UMI_PRINCIPAL_ID/memberOf" \
  --query "value[?displayName=='Directory Readers'].displayName" \
  -o tsv 2>/dev/null)

if [ -n "$VERIFICATION" ]; then
  echo "   ✓ Verification successful: UMI has Directory Readers role"
  echo ""
  echo "=== SUCCESS ==="
  echo "You can now proceed with your Terraform MySQL configuration!"
  echo ""
  echo "Next steps:"
  echo "1. Wait 2-3 minutes for role assignment to fully propagate"
  echo "2. Run: terraform apply"
else
  echo "   ⚠️  Verification inconclusive - role assignment may still be propagating"
  echo "   Wait 5 minutes and check manually in Azure Portal"
fi

echo ""
echo "=== VERIFICATION COMMANDS ==="
echo "Check role assignment:"
echo "az rest --method GET --uri 'https://graph.microsoft.com/v1.0/servicePrincipals/$UMI_PRINCIPAL_ID/memberOf' --query \"value[?displayName=='Directory Readers']\""
echo ""
echo "Test MySQL connection:"
echo "TOKEN=\$(az account get-access-token --resource https://ossrdbms-aad.database.windows.net --query accessToken -o tsv)"
echo "mysql -h tf-mysql-poc-001.mysql.database.azure.com -u umi-admin --enable-cleartext-plugin --password=\"\$TOKEN\""