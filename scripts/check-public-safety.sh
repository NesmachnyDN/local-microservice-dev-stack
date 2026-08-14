#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

fail=0

tracked_sensitive_files=$(find . -type f \
  \( -name '.env' -o -name '*.pem' -o -name '*.key' -o -name '*.p12' -o -name '*.pfx' -o -name '*.jks' \) \
  -not -path './.git/*' -print)

if [[ -n "$tracked_sensitive_files" ]]; then
  echo 'Potentially sensitive files found:' >&2
  echo "$tracked_sensitive_files" >&2
  fail=1
fi

scan_files=$(find . -type f -not -path './.git/*' -not -name '*.zip' -print)

check_pattern() {
  local description="$1"
  local pattern="$2"
  if grep -nEI "$pattern" $scan_files >/tmp/public-safety-match.txt 2>/dev/null; then
    echo "Potential $description found:" >&2
    cat /tmp/public-safety-match.txt >&2
    fail=1
  fi
}

check_pattern 'private key material' '-----BEGIN (RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----'
check_pattern 'cloud or GitHub token' '(gh[pousr]_[A-Za-z0-9_]{20,}|AKIA[0-9A-Z]{16})'
check_pattern 'RFC1918 IPv4 address' '(^|[^0-9])(10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|192\.168\.[0-9]{1,3}\.[0-9]{1,3}|172\.(1[6-9]|2[0-9]|3[01])\.[0-9]{1,3}\.[0-9]{1,3})([^0-9]|$)'
check_pattern 'internal/corporate hostname' '([A-Za-z0-9-]+\.)+(corp|internal|intranet)(\.|[:/]|$)'
check_pattern 'credential embedded in URL' '[a-z][a-z0-9+.-]*://[^[:space:]/:@]+:[^[:space:]@/]+@'

exit "$fail"
