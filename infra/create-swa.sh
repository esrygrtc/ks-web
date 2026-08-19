#!/bin/bash
# ADR-W1 resource: the one Static Web App. Idempotent: re-running
# neither errors nor duplicates (gate W0 asserts this).
set -euo pipefail
RG=keepstate-web-rg           # pre-dates the ks-only naming rule; see ADR-W1
NAME=ks-web
LOC=westeurope
if az staticwebapp show -n "$NAME" -g "$RG" >/dev/null 2>&1; then
  echo "exists: $NAME ($(az staticwebapp show -n "$NAME" -g "$RG" --query defaultHostname -o tsv))"
else
  az staticwebapp create -n "$NAME" -g "$RG" -l "$LOC" --sku Standard \
    --query '{name:name, host:defaultHostname, sku:sku.name}' -o json
fi
