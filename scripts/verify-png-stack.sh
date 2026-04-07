#!/usr/bin/env bash
# Verify Pits N Giggles is up and dashboard pages include the AI drawer embed.
# Optionally check MCP server and nginx proxy health (docker MCP stack).
#
# Usage:
#   scripts/verify-png-stack.sh
#   scripts/verify-png-stack.sh --mcp
#   scripts/verify-png-stack.sh --mcp --nginx-proxy
#   scripts/verify-png-stack.sh --mcp-stack-only   # MCP + nginx only (no PNG); implies --mcp --nginx-proxy
#
# Env:
#   PNG_BASE     Base URL for host PNG (default http://127.0.0.1:4768)
#   MCP_HEALTH   MCP health URL (default http://127.0.0.1:8765/health)
#   NGINX_HEALTH HTTP health via nginx (default http://127.0.0.1:9080/health)

set -u

PNG_BASE="${PNG_BASE:-http://127.0.0.1:4768}"
MCP_HEALTH="${MCP_HEALTH:-http://127.0.0.1:8765/health}"
NGINX_HEALTH="${NGINX_HEALTH:-http://127.0.0.1:9080/health}"

CHECK_MCP=false
CHECK_NGINX=false
SKIP_PNG=false
while [ $# -gt 0 ]; do
  case "$1" in
    --mcp) CHECK_MCP=true ;;
    --nginx-proxy) CHECK_NGINX=true ;;
    --mcp-stack-only)
      SKIP_PNG=true
      CHECK_MCP=true
      CHECK_NGINX=true
      ;;
    -h|--help)
      echo "Usage: $0 [--mcp] [--nginx-proxy] [--mcp-stack-only]"
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 2
      ;;
  esac
  shift
done

FAIL=0
red() { printf '\033[0;31m%s\033[0m\n' "$*"; }
green() { printf '\033[0;32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[1;33m%s\033[0m\n' "$*"; }

verify_png_page() {
  local path="$1"
  local label="$2"
  local url="${PNG_BASE}${path}"
  local body tmp
  tmp=$(mktemp)
  if ! code=$(curl -sS -o "$tmp" -w '%{http_code}' --max-time 8 "$url"); then
    red "PNG $label: request failed (${url})"
    rm -f "$tmp"
    FAIL=1
    return
  fi
  if [ "$code" != "200" ]; then
    red "PNG $label: HTTP $code (${url})"
    rm -f "$tmp"
    FAIL=1
    return
  fi
  body=$(cat "$tmp")
  rm -f "$tmp"
  if ! printf '%s' "$body" | grep -q 'png-ai-drawer'; then
    red "PNG $label: missing AI drawer markup (png-ai-drawer)"
    FAIL=1
    return
  fi
  if ! printf '%s' "$body" | grep -qE 'ai-drawer\.(js|css)'; then
    red "PNG $label: missing ai-drawer asset references"
    FAIL=1
    return
  fi
  green "PNG $label: OK ($url)"
}

echo ""
if [ "$SKIP_PNG" = true ]; then
  echo "MCP + nginx stack verification (PNG skipped)"
else
  echo "Pits N Giggles stack verification"
fi
echo "─────────────────────────────────"

if [ "$SKIP_PNG" != true ]; then
  verify_png_page "/" "Driver view"
  verify_png_page "/eng-view" "Engineer view"
fi

if [ "$CHECK_MCP" = true ]; then
  if code=$(curl -sS -o /dev/null -w '%{http_code}' --max-time 8 "$MCP_HEALTH"); then
    if [ "$code" = "200" ]; then
      green "MCP health: OK ($MCP_HEALTH)"
    else
      red "MCP health: HTTP $code ($MCP_HEALTH)"
      FAIL=1
    fi
  else
    red "MCP health: unreachable ($MCP_HEALTH)"
    FAIL=1
  fi
fi

if [ "$CHECK_NGINX" = true ]; then
  if code=$(curl -sS -o /dev/null -w '%{http_code}' --max-time 8 "$NGINX_HEALTH"); then
    if [ "$code" = "200" ]; then
      green "nginx proxy health: OK ($NGINX_HEALTH)"
    else
      yellow "nginx proxy health: HTTP $code ($NGINX_HEALTH) — check HTTP_PORT in .env.mcp"
      FAIL=1
    fi
  else
    red "nginx proxy health: unreachable ($NGINX_HEALTH)"
    FAIL=1
  fi
fi

echo ""
if [ "$FAIL" -ne 0 ]; then
  red "Verification finished with failures."
  exit 1
fi
green "All checks passed."
exit 0
