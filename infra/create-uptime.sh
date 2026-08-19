#!/bin/bash
# NOT YET RUN: creates Application Insights + a standard availability
# test pinging https://keepstate.ai/ every 5 minutes from 3 regions,
# alerting the founder's email. NEW COST beyond the pre-approved list
# (~$2-5/mo ingestion): the founder approves before this script runs.
set -euo pipefail
RG=ks-web-rg
LOC=westeurope
EMAIL="${1:?usage: create-uptime.sh founder@email}"
az monitor log-analytics workspace create -g $RG -n ks-web-logs -l $LOC --query name -o tsv
AI=$(az monitor app-insights component create -g $RG --app ks-web-ping -l $LOC \
  --workspace ks-web-logs --query id -o tsv)
az monitor app-insights web-test create -g $RG -n ks-web-uptime -l $LOC \
  --web-test-kind standard --enabled true --frequency 300 --timeout 30 \
  --http-verb GET --request-url "https://keepstate.ai/" --retry-enabled true \
  --locations Id="emea-nl-ams-azr" --locations Id="emea-gb-db3-azr" --locations Id="us-va-ash-azr" \
  --defined-web-test-name ks-web-uptime --tags "hidden-link:$AI=Resource"
AG=$(az monitor action-group create -g $RG -n ks-web-alerts --short-name kswebalrt \
  --action email founder "$EMAIL" --query id -o tsv)
az monitor metrics alert create -g $RG -n ks-web-down \
  --scopes "$AI" --condition "avg availabilityResults/availabilityPercentage < 100" \
  --window-size 5m --evaluation-frequency 5m --action "$AG" \
  --description "keepstate.ai availability dropped below 100%"
echo "uptime test + alert live; test-fire by disabling the site or az monitor metrics alert test"
