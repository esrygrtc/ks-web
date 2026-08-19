#!/bin/bash
# Adds keepstate.ai + www to the SWA. Run AFTER the founder sets DNS.
set -euo pipefail
RG=ks-web-rg
APP=ks-web
az staticwebapp hostname set -n $APP -g $RG --hostname www.keepstate.ai --no-wait
az staticwebapp hostname set -n $APP -g $RG --hostname keepstate.ai --validation-method dns-txt-token --no-wait
echo "validation state + any TXT token to add:"
az staticwebapp hostname list -n $APP -g $RG -o table
