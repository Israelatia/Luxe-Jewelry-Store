#!/usr/bin/env bash
set -euo pipefail

IMG="${1:-mysite:latest}"
NAME="mysite-test-$$"

echo "Starting $NAME from image: $IMG"
docker run -d --rm -p 8080:80 --name "$NAME" "$IMG"

cleanup() { docker rm -f "$NAME" >/dev/null 2>&1 || true; }
trap cleanup EXIT

# wait for nginx to be ready
for i in {1..30}; do
  if curl -fsS http://localhost:8080/healthz >/dev/null; then
    break
  fi
  sleep 1
done

# Assert homepage contains the React root div
curl -fsS http://localhost:8080/ | grep -i 'id="root"' >/dev/null

echo "✅ Test passed"
