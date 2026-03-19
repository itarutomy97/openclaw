#!/bin/bash
# OpenClaw VPS Health Check Script
# Run this on startup or periodically via cron

set -e

ERRORS=0

# Load NVM for Node.js and npm-installed tools
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

echo "=== OpenClaw Health Check ==="
echo "Time: $(date)"
echo

# Check 1: ZAI_API_KEY (check in .env file since systemd loads it)
ENV_FILE="/root/.openclaw/.env"
if [ -f "$ENV_FILE" ] && grep -q "^ZAI_API_KEY=." "$ENV_FILE"; then
    echo "✅ ZAI_API_KEY: present in .env"
else
    echo "❌ ERROR: ZAI_API_KEY is not set in $ENV_FILE"
    ERRORS=$((ERRORS + 1))
fi

# Check 2: LINE credentials in openclaw.json
OPENCLAW_CONFIG="/root/.openclaw/openclaw.json"
if [ -f "$OPENCLAW_CONFIG" ]; then
    if grep -q '"channelAccessToken"' "$OPENCLAW_CONFIG" && grep -q '"channelSecret"' "$OPENCLAW_CONFIG"; then
        echo "✅ LINE credentials: present in openclaw.json"
    else
        echo "❌ ERROR: LINE credentials missing in openclaw.json"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo "❌ ERROR: openclaw.json not found"
    ERRORS=$((ERRORS + 1))
fi

# Check 3: Gateway service running
if systemctl --user is-active --quiet openclaw-gateway.service; then
    echo "✅ Gateway service: running"
else
    echo "❌ ERROR: Gateway service not running"
    ERRORS=$((ERRORS + 1))
fi

# Check 4: Cloudflare tunnel
if systemctl is-active --quiet cloudflared; then
    echo "✅ Cloudflare tunnel: running"
else
    echo "⚠️  WARNING: Cloudflare tunnel not running"
fi

# Check 5: Recent errors in logs
RECENT_ERRORS=$(journalctl --user -u openclaw-gateway.service --since "5 minutes ago" 2>/dev/null | grep -ci "error\|failed\|No API key" || true)
if [ "${RECENT_ERRORS:-0}" -gt 0 ]; then
    echo "⚠️  WARNING: $RECENT_ERRORS error(s) in last 5 minutes"
else
    echo "✅ No recent errors in logs"
fi

# Check 6: QMD (Query Markdown Documents)
if command -v qmd &> /dev/null; then
    QMD_VERSION=$(qmd --version 2>/dev/null || echo "unknown")
    echo "✅ QMD CLI: installed ($QMD_VERSION)"

    # Check if openclaw-main collection exists
    if qmd collection list 2>/dev/null | grep -q "openclaw-main"; then
        # Get collection stats
        COLLECTION_INFO=$(qmd collection list 2>/dev/null | grep -A 2 "openclaw-main" || echo "")
        FILES_COUNT=$(echo "$COLLECTION_INFO" | grep "Files:" | awk '{print $2}' || echo "0")
        echo "✅ QMD collection 'openclaw-main': $FILES_COUNT files indexed"
    else
        echo "⚠️  WARNING: QMD collection 'openclaw-main' not found (run: qmd collection add ~/.openclaw/workspace --name openclaw-main --mask '**/*.md')"
    fi
else
    echo "⚠️  WARNING: QMD CLI not installed (optional feature)"
fi

echo
echo "=== Summary ==="
if [ "$ERRORS" -gt 0 ]; then
    echo "❌ $ERRORS error(s) found"
    echo
    echo "To fix, run: /root/openclaw/xserver/scripts/sync-config.sh"
    exit 1
else
    echo "✅ All checks passed"
    exit 0
fi
