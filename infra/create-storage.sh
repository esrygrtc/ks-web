#!/bin/bash
# ADR-W2 resource: the leads storage account. Idempotent. Tables:
# leads (design-partner intake), grants, subscribers, contact.
# A lead is durable BEFORE any email is attempted; we do not lose sessions.
set -euo pipefail
RG=ks-web-rg
NAME=kswebleads
LOC=westeurope
if ! az storage account show -n "$NAME" -g "$RG" >/dev/null 2>&1; then
  az storage account create -n "$NAME" -g "$RG" -l "$LOC" \
    --sku Standard_LRS --kind StorageV2 --min-tls-version TLS1_2 \
    --allow-blob-public-access false \
    --query '{name:name, sku:sku.name}' -o json
else
  echo "exists: $NAME"
fi
KEY=$(az storage account keys list -n "$NAME" -g "$RG" --query '[0].value' -o tsv)
for T in leads grants subscribers contact; do
  az storage table create --name "$T" --account-name "$NAME" --account-key "$KEY" --only-show-errors -o none && echo "table: $T"
done
