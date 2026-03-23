#!/bin/bash
# deploy-workspace.sh - Deploy workspace files (SOUL.md, AGENTS.md, etc.) to VPS
#
# Usage: ./deploy-workspace.sh [instance|all]
#   instance: alpha, beta, sudax, tight, onagigawa, main-line, main-slack, main-telegram, all
#   default: all
#
# Also syncs API keys (BRAVE_API_KEY, TAVILY_API_KEY) from Main .env to all instances
#
# IMPORTANT: Workspace files live at ~/.openclaw/workspace-{profile}
# NOT at ~/.openclaw-{profile}/workspace (that's the old wrong path)
# This is because OPENCLAW_PROFILE={profile} sets workspace to workspace-{profile}
#
# Exception: main-line has no PROFILE, so it uses ~/.openclaw/workspace/

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOUL_DIR="${SCRIPT_DIR}/../soul"

INSTANCES="${1:-all}"

# Files to deploy (order matters for some)
DEPLOY_FILES="SOUL AGENTS IDENTITY USER TOOLS HEARTBEAT BOOTSTRAP"

deploy_instance() {
    local inst="$1"
    local soul_prefix="$2"
    local ws="$3"

    echo "=== Deploying ${inst} (prefix: ${soul_prefix}, workspace: ${ws}) ==="

    # Backup existing files first
    if [ -d "$ws" ]; then
        BACKUP_DIR="${ws}-backup-$(date +%Y%m%d-%H%M%S)"
        cp -r "$ws" "$BACKUP_DIR"
        echo "  Backed up to ${BACKUP_DIR}"
    fi

    mkdir -p "$ws"

    # Deploy standard files
    for file in $DEPLOY_FILES; do
        SRC="${SOUL_DIR}/${soul_prefix}-${file}.md"
        if [ -f "$SRC" ]; then
            cp "$SRC" "${ws}/${file}.md"
            echo "  ${file}.md deployed"
        else
            echo "  ${file}.md not found in soul/ (skipped)"
        fi
    done

    # Deploy extra files (SOUL-telegram, MEMORY, PERSISTENT_CONTEXT_SETUP, ARXIV_DAILY, etc.)
    for extra in "${SOUL_DIR}/${soul_prefix}-"*.md; do
        if [ -f "$extra" ]; then
            basename_file=$(basename "$extra")
            # Strip prefix to get target filename
            target_name="${basename_file#${soul_prefix}-}"
            # Skip standard files already deployed
            case "$target_name" in
                SOUL.md|AGENTS.md|IDENTITY.md|USER.md|TOOLS.md|HEARTBEAT.md|BOOTSTRAP.md)
                    continue
                    ;;
            esac
            cp "$extra" "${ws}/${target_name}"
            echo "  ${target_name} deployed (extra)"
        fi
    done
}

# Define all instances with their soul prefix and workspace path
deploy_all() {
    # Discord instances
    deploy_instance "alpha"          "alpha"          "/root/.openclaw/workspace-alpha"
    deploy_instance "beta"           "beta"           "/root/.openclaw/workspace-beta"
    deploy_instance "sudax"          "sudax"          "/root/.openclaw/workspace-sudax"
    deploy_instance "tight"          "tight"          "/root/.openclaw/workspace-tight"
    deploy_instance "onagigawa"      "onagigawa"      "/root/.openclaw/workspace-onagigawa"

    # Main channel instances
    deploy_instance "main-line"      "main-line"      "/root/.openclaw/workspace"
    deploy_instance "main-slack"     "main-slack"     "/root/.openclaw/workspace-slack"
    deploy_instance "main-telegram"  "main-telegram"  "/root/.openclaw/workspace-telegram"
}

if [ "$INSTANCES" = "all" ]; then
    deploy_all
else
    case "$INSTANCES" in
        alpha|beta|sudax|tight|onagigawa)
            deploy_instance "$INSTANCES" "$INSTANCES" "/root/.openclaw/workspace-${INSTANCES}"
            ;;
        main-line)
            deploy_instance "main-line" "main-line" "/root/.openclaw/workspace"
            ;;
        main-slack)
            deploy_instance "main-slack" "main-slack" "/root/.openclaw/workspace-slack"
            ;;
        main-telegram)
            deploy_instance "main-telegram" "main-telegram" "/root/.openclaw/workspace-telegram"
            ;;
        *)
            echo "Unknown instance: $INSTANCES"
            echo "Valid: alpha, beta, sudax, tight, onagigawa, main-line, main-slack, main-telegram, all"
            exit 1
            ;;
    esac
fi

echo ""
echo "=== Syncing API keys to all instances ==="
MAIN_ENV="/root/.openclaw/.env"
ALL_INSTANCES="alpha beta sudax tight onagigawa slack telegram"
for key in BRAVE_API_KEY TAVILY_API_KEY ZAI_API_KEY; do
    VAL=$(grep "^${key}=" "$MAIN_ENV" 2>/dev/null | head -1 | sed "s/^${key}=//")
    if [ -n "$VAL" ]; then
        for inst in $ALL_INSTANCES; do
            ENV_FILE="/root/.openclaw-${inst}/.env"
            if [ -f "$ENV_FILE" ]; then
                if grep -q "^${key}=" "$ENV_FILE" 2>/dev/null; then
                    sed -i "s|^${key}=.*|${key}=${VAL}|" "$ENV_FILE"
                else
                    echo "${key}=${VAL}" >> "$ENV_FILE"
                    echo "  ${inst}: ${key} added"
                fi
            fi
        done
    fi
done
echo "  done"

echo ""
echo "=== Clearing sessions ==="
rm -rf /root/.openclaw-*/agents/*/sessions/*
rm -rf /root/.openclaw/agents/*/sessions/*
echo "  done"

echo ""
echo "=== Restarting services ==="
ALL_SERVICES="openclaw-gateway.service openclaw-gateway-alpha.service openclaw-gateway-beta.service openclaw-gateway-sudax.service openclaw-gateway-tight.service openclaw-gateway-onagigawa.service openclaw-gateway-slack.service openclaw-gateway-telegram.service"

if [ "$INSTANCES" = "all" ]; then
    systemctl --user restart $ALL_SERVICES
else
    case "$INSTANCES" in
        main-line)
            systemctl --user restart openclaw-gateway.service
            ;;
        main-slack)
            systemctl --user restart openclaw-gateway-slack.service
            ;;
        main-telegram)
            systemctl --user restart openclaw-gateway-telegram.service
            ;;
        *)
            systemctl --user restart "openclaw-gateway-${INSTANCES}.service"
            ;;
    esac
fi

sleep 5
echo ""
echo "=== Status ==="
if [ "$INSTANCES" = "all" ]; then
    systemctl --user is-active $ALL_SERVICES
else
    case "$INSTANCES" in
        main-line)
            systemctl --user is-active openclaw-gateway.service
            ;;
        main-slack)
            systemctl --user is-active openclaw-gateway-slack.service
            ;;
        main-telegram)
            systemctl --user is-active openclaw-gateway-telegram.service
            ;;
        *)
            systemctl --user is-active "openclaw-gateway-${INSTANCES}.service"
            ;;
    esac
fi

echo ""
echo "=== DEPLOY COMPLETE ==="
