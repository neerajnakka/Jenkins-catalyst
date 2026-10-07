#!/usr/bin/env bash
# Loaded with:  writeFile(file:'smoke.sh', text: libraryResource('scripts/smoke-test.sh'))
set -euo pipefail
URL="${1:?usage: smoke-test.sh http://localhost:3000}"
ATTEMPTS="${2:-30}"

for i in $(seq 1 "$ATTEMPTS"); do
  if curl -fsS "$URL/health" > /dev/null; then
    echo "healthy after ${i} attempt(s)"
    exit 0
  fi
  sleep 2
done

echo "service never became healthy at ${URL}"
exit 1
