#!/bin/bash
# deploy-workspace.sh - Deploy workspace files (SOUL.md, AGENTS.md, etc.) to VPS
#
# Usage: ./deploy-workspace.sh [instance]
#   instance: alpha, beta, sudax, tight, onagigawa, all (default: all)
#
# Also syncs API keys (BRAVE_API_KEY, TAVILY_API_KEY) from Main .env to all instances
#
# IMPORTANT: Workspace files live at ~/.openclaw/workspace-{profile}
# NOT at ~/.openclaw-{profile}/workspace (that's the old wrong path)
# This is because OPENCLAW_PROFILE={profile} sets workspace to workspace-{profile}

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOUL_DIR="${SCRIPT_DIR}/../soul"

INSTANCES="${1:-all}"

deploy_instance() {
    local inst="$1"
    local WS="/root/.openclaw/workspace-${inst}"

    echo "=== Deploying ${inst} ==="

    # Backup existing files first
    if [ -d "$WS" ]; then
        BACKUP_DIR="/root/.openclaw/workspace-${inst}-backup-$(date +%Y%m%d-%H%M%S)"
        cp -r "$WS" "$BACKUP_DIR"
        echo "  Backed up to ${BACKUP_DIR}"
    fi

    mkdir -p "$WS"

    # Deploy files from soul/ directory
    for file in SOUL AGENTS IDENTITY USER; do
        SRC="${SOUL_DIR}/${inst}-${file}.md"
        if [ -f "$SRC" ]; then
            cp "$SRC" "${WS}/${file}.md"
            echo "  ${file}.md deployed"
        else
            echo "  ${file}.md not found in soul/ (skipped)"
        fi
    done
}

if [ "$INSTANCES" = "all" ]; then
    for inst in alpha beta sudax tight onagigawa; do
        deploy_instance "$inst"
    done
else
    deploy_instance "$INSTANCES"
fi

echo ""
echo "=== Syncing API keys to all instances ==="
MAIN_ENV="/root/.openclaw/.env"
for key in BRAVE_API_KEY TAVILY_API_KEY; do
    VAL=$(grep "^${key}=" "$MAIN_ENV" 2>/dev/null | head -1 | sed "s/^${key}=//")
    if [ -n "$VAL" ]; then
        for inst in alpha beta sudax tight onagigawa; do
            ENV_FILE="/root/.openclaw-${inst}/.env"
            if ! grep -q "^${key}=" "$ENV_FILE" 2>/dev/null; then
                echo "${key}=${VAL}" >> "$ENV_FILE"
                echo "  ${inst}: ${key} added"
            fi
        done
    fi
done
echo "  done"

echo ""
echo "=== Clearing sessions ==="
rm -rf /root/.openclaw-*/agents/*/sessions/*
echo "  done"

echo ""
echo "=== Restarting services ==="
if [ "$INSTANCES" = "all" ]; then
    systemctl --user restart openclaw-gateway-alpha.service openclaw-gateway-beta.service openclaw-gateway-sudax.service openclaw-gateway-tight.service openclaw-gateway-onagigawa.service
else
    systemctl --user restart "openclaw-gateway-${INSTANCES}.service"
fi

sleep 5
echo ""
echo "=== Status ==="
if [ "$INSTANCES" = "all" ]; then
    systemctl --user is-active openclaw-gateway-alpha.service openclaw-gateway-beta.service openclaw-gateway-sudax.service openclaw-gateway-tight.service
else
    systemctl --user is-active "openclaw-gateway-${INSTANCES}.service"
fi

echo ""
echo "=== DEPLOY COMPLETE ==="
