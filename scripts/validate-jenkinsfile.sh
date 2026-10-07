#!/usr/bin/env bash
# Block 3 — validate a Jenkinsfile WITHOUT running a build.
# Usage: JENKINS_USER=admin JENKINS_TOKEN=xxxx ./scripts/validate-jenkinsfile.sh nodejs-app/Jenkinsfile
set -euo pipefail
JENKINS_URL="${JENKINS_URL:-http://localhost:8080}"
USER="${JENKINS_USER:?set JENKINS_USER}"
TOKEN="${JENKINS_TOKEN:?set JENKINS_TOKEN (Manage Jenkins -> your user -> Security -> API Token)}"
FILE="${1:?usage: $0 <path-to-Jenkinsfile>}"

CRUMB=$(curl -s -u "$USER:$TOKEN" \
  "$JENKINS_URL/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,\":\",//crumb)")

curl -s -u "$USER:$TOKEN" -H "$CRUMB" \
     -F "jenkinsfile=<$FILE" \
     "$JENKINS_URL/pipeline-model-converter/validate" | tee /tmp/validate.out

if grep -q "successfully validated" /tmp/validate.out; then
  echo "✅ Jenkinsfile is valid: $FILE"
else
  echo "❌ Jenkinsfile has errors: $FILE"; exit 1
fi
