#!/usr/bin/env bash
# One-time bootstrap: remote state storage + GitHub OIDC identity.
# Run locally after `az login`. Idempotent. Needs: az, gh (authenticated for the repo).
#
#   GITHUB_REPO=<owner>/azure-simple-lab ALERT_EMAIL=you@example.com ./scripts/bootstrap.sh
set -euo pipefail

: "${GITHUB_REPO:?set GITHUB_REPO=owner/repo}"
: "${ALERT_EMAIL:?set ALERT_EMAIL}"
LOCATION="${LOCATION:-norwayeast}"
SUB_ID="$(az account show --query id -o tsv)"
TENANT_ID="$(az account show --query tenantId -o tsv)"
SUFFIX="$(echo -n "$SUB_ID" | md5 2>/dev/null | cut -c1-5 || echo -n "$SUB_ID" | md5sum | cut -c1-5)"
TFSTATE_RG="lab-tfstate-rg"
TFSTATE_SA="labtfstate${SUFFIX}"

echo "==> State storage ($TFSTATE_SA)"
az group create -n "$TFSTATE_RG" -l "$LOCATION" -o none
az storage account create -n "$TFSTATE_SA" -g "$TFSTATE_RG" -l "$LOCATION" \
  --sku Standard_LRS --min-tls-version TLS1_2 --allow-blob-public-access false \
  --allow-shared-key-access false -o none
az storage account blob-service-properties update --account-name "$TFSTATE_SA" -g "$TFSTATE_RG" \
  --enable-versioning true --enable-delete-retention true --delete-retention-days 14 -o none
SA_ID="$(az storage account show -n "$TFSTATE_SA" -g "$TFSTATE_RG" --query id -o tsv)"
ME="$(az ad signed-in-user show --query id -o tsv)"
az role assignment create --assignee "$ME" --role "Storage Blob Data Owner" --scope "$SA_ID" -o none || true
echo "   waiting for RBAC to propagate..."; sleep 30
az storage container create --account-name "$TFSTATE_SA" -n tfstate --auth-mode login -o none

echo "==> Entra app + federated credentials (no secrets)"
APP_ID="$(az ad app list --display-name lab-github-terraform --query '[0].appId' -o tsv)"
if [ -z "$APP_ID" ]; then APP_ID="$(az ad app create --display-name lab-github-terraform --query appId -o tsv)"; fi
az ad sp show --id "$APP_ID" >/dev/null 2>&1 || az ad sp create --id "$APP_ID" -o none
APP_OBJ="$(az ad app show --id "$APP_ID" --query id -o tsv)"
# Newer GitHub accounts/orgs issue immutable-ID subjects (owner@id/repo@id) instead of names.
OWNER="${GITHUB_REPO%%/*}"; REPO_NAME="${GITHUB_REPO##*/}"
OWNER_ID="$(gh api "repos/$GITHUB_REPO" --jq .owner.id)"; REPO_ID="$(gh api "repos/$GITHUB_REPO" --jq .id)"
SUBJECT_PREFIX="repo:${OWNER}@${OWNER_ID}/${REPO_NAME}@${REPO_ID}"

# One federated credential per GitHub Environment: the token subject is pinned to
# repo + environment, so a fork/branch/other workflow can't mint a usable token.
for E in dev-plan prd-plan dev prd; do
  az ad app federated-credential delete --id "$APP_OBJ" --federated-credential-id "gh-$E" 2>/dev/null || true
  az ad app federated-credential create --id "$APP_OBJ" --parameters "{
    \"name\": \"gh-$E\",
    \"issuer\": \"https://token.actions.githubusercontent.com\",
    \"subject\": \"${SUBJECT_PREFIX}:environment:${E}\",
    \"audiences\": [\"api://AzureADTokenExchange\"]}" -o none 2>/dev/null || true
done

echo "==> RBAC: Contributor, conditional RBAC Administrator (Key Vault Secrets User only), blob owner on state"
az role assignment create --assignee "$APP_ID" --role Contributor --scope "/subscriptions/$SUB_ID" -o none || true
az role assignment create --assignee "$APP_ID" --role "Storage Blob Data Owner" --scope "$SA_ID" -o none || true

# Contributor cannot create role assignments, and the aks-bootstrap layer must give each pod's identity
# access to Key Vault. Give the pipeline identity RBAC Administrator, but with an ABAC condition so it can
# only assign (or remove) the single role "Key Vault Secrets User". It cannot grant Owner/Contributor.
KVSU=4633458b-17de-408a-b874-0445c86b69e6
COND="((!(ActionMatches{'Microsoft.Authorization/roleAssignments/write'})) OR (@Request[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {$KVSU})) AND ((!(ActionMatches{'Microsoft.Authorization/roleAssignments/delete'})) OR (@Resource[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {$KVSU}))"
RBAC_SCOPE="${RBAC_SCOPE:-/subscriptions/$SUB_ID}"   # tighten to a resource group once it exists
az role assignment create --assignee "$APP_ID" --role "Role Based Access Control Administrator" \
  --scope "$RBAC_SCOPE" --condition "$COND" --condition-version 2.0 -o none || true

echo "==> GitHub environments + variables"
for E in dev dev-plan prd prd-plan; do
  gh api -X PUT "repos/$GITHUB_REPO/environments/$E" -i >/dev/null
  gh variable set AZURE_CLIENT_ID       --env "$E" --repo "$GITHUB_REPO" --body "$APP_ID"
  gh variable set AZURE_TENANT_ID       --env "$E" --repo "$GITHUB_REPO" --body "$TENANT_ID"
  gh variable set AZURE_SUBSCRIPTION_ID --env "$E" --repo "$GITHUB_REPO" --body "$SUB_ID"
  gh variable set TFSTATE_RG            --env "$E" --repo "$GITHUB_REPO" --body "$TFSTATE_RG"
  gh variable set TFSTATE_SA            --env "$E" --repo "$GITHUB_REPO" --body "$TFSTATE_SA"
  gh variable set ALERT_EMAIL           --env "$E" --repo "$GITHUB_REPO" --body "$ALERT_EMAIL"
done

cat <<MSG

Done. Manual steps left:
  1. Repo secret MODULES_READ_TOKEN: fine-grained PAT with read-only 'Contents' on anasmohana/terraform-modules
       gh secret set MODULES_READ_TOKEN --repo $GITHUB_REPO
  2. Approval gate: the workflows open an issue and wait for the repo owner to comment 'approve'.
     (GitHub environment reviewers need a paid plan on private repos; if you have one, you can add them instead.)
  3. Protect 'main' (PR + status checks required).
MSG
