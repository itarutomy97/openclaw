#!/bin/bash
# restore-vps.sh
# Complete OpenClaw VPS restoration script
#
# This script restores all OpenClaw configuration to a fresh VPS
#
# Prerequisites:
#   - Ubuntu 24.04 LTS
#   - Root access
#   - This script and config files in the same directory
#
# Usage: ./restore-vps.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")/config"
ENV_FILE="$(dirname "$SCRIPT_DIR")/.env.backup"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    log_error "Please run as root"
    exit 1
fi

# Load environment variables
if [ -f "$ENV_FILE" ]; then
    log_info "Loading environment variables from $ENV_FILE"
    set -a
    source "$ENV_FILE"
    set +a
else
    log_error "Environment file not found: $ENV_FILE"
    exit 1
fi

echo ""
echo "=========================================="
echo "  OpenClaw VPS Restoration Script"
echo "=========================================="
echo ""

# Step 1: Install Node.js via NVM
log_info "Step 1: Installing Node.js via NVM..."
if [ ! -d "$HOME/.nvm" ]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

if ! command -v node &> /dev/null; then
    nvm install 24
    nvm use 24
fi

NODE_VERSION=$(node -v)
log_info "Node.js version: $NODE_VERSION"

# Step 2: Install OpenClaw
log_info "Step 2: Installing OpenClaw..."
if ! command -v openclaw &> /dev/null; then
    npm install -g openclaw
fi

OPENCLAW_VERSION=$(openclaw --version 2>/dev/null || echo "unknown")
log_info "OpenClaw version: $OPENCLAW_VERSION"

# Step 3: Create OpenClaw config directory
log_info "Step 3: Setting up OpenClaw configuration..."
mkdir -p "$HOME/.openclaw"

# Copy openclaw.json
if [ -f "$CONFIG_DIR/../openclaw.json" ]; then
    cp "$CONFIG_DIR/../openclaw.json" "$HOME/.openclaw/openclaw.json"
    log_info "Copied openclaw.json"
else
    log_error "openclaw.json not found"
    exit 1
fi

# Step 4: Install OpenClaw gateway as systemd service
log_info "Step 4: Installing OpenClaw gateway service..."
openclaw gateway install --port 18789

# Step 5: Add ZAI_API_KEY to systemd service
log_info "Step 5: Adding ZAI_API_KEY to systemd service..."
SERVICE_FILE="$HOME/.config/systemd/user/openclaw-gateway.service"

if [ -f "$SERVICE_FILE" ]; then
    # Check if ZAI_API_KEY already exists
    if ! grep -q "ZAI_API_KEY" "$SERVICE_FILE"; then
        # Add ZAI_API_KEY environment variable
        sed -i "/Environment=OPENCLAW_SERVICE_VERSION/a Environment=ZAI_API_KEY=$ZAI_API_KEY" "$SERVICE_FILE"
        log_info "Added ZAI_API_KEY to systemd service"
    else
        log_warn "ZAI_API_KEY already exists in service file"
    fi
else
    log_error "Systemd service file not found: $SERVICE_FILE"
    exit 1
fi

# Step 6: Set up auto-patch system (survives npm update)
log_info "Step 6: Setting up auto-patch system..."
mkdir -p /root/openclaw-scripts

# Copy auto-patch script
AUTO_PATCH="$SCRIPT_DIR/auto-line-patch.sh"
if [ -f "$AUTO_PATCH" ]; then
    cp "$AUTO_PATCH" /root/openclaw-scripts/auto-line-patch.sh
    chmod +x /root/openclaw-scripts/auto-line-patch.sh
    log_info "Auto-patch script installed to /root/openclaw-scripts/"
else
    log_warn "Auto-patch script not found: $AUTO_PATCH"
fi

# Add ExecStartPre to systemd service for auto-patching
SERVICE_FILE="$HOME/.config/systemd/user/openclaw-gateway.service"
if [ -f "$SERVICE_FILE" ]; then
    if ! grep -q "ExecStartPre.*auto-line-patch" "$SERVICE_FILE"; then
        sed -i '/^ExecStart=/i ExecStartPre=/root/openclaw-scripts/auto-line-patch.sh' "$SERVICE_FILE"
        log_info "Added ExecStartPre to systemd service for auto-patching"
    fi
fi

# Apply LINE patch now (will be auto-applied on future restarts too)
/root/openclaw-scripts/auto-line-patch.sh 2>/dev/null || true

# Step 7: Install and configure cloudflared
log_info "Step 7: Setting up Cloudflare tunnel..."
if [ ! -f /usr/local/bin/cloudflared ]; then
    curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
    dpkg -i cloudflared.deb
    rm cloudflared.deb
fi

# Install cloudflared as systemd service
if [ ! -f /etc/systemd/system/cloudflared.service ]; then
    cp "$CONFIG_DIR/cloudflared.service" /etc/systemd/system/cloudflared.service"
    systemctl daemon-reload
    systemctl enable cloudflared
    log_info "Cloudflare tunnel service installed"
else
    log_warn "Cloudflare tunnel already configured"
fi

# Step 7.5: Install Camofox Browser plugin
log_info "Step 7.5: Installing Camofox Browser plugin..."
openclaw plugins install @askjo/camofox-browser 2>/dev/null || log_warn "Camofox plugin installation failed (may already exist)"

# Step 7.6: Install QMD (Query Markdown Documents)
log_info "Step 7.6: Installing QMD (Query Markdown Documents)..."

# Install build tools for native modules
if ! command -v make &> /dev/null; then
    log_info "Installing build-essential for QMD..."
    apt-get update -qq
    apt-get install -y build-essential python3 > /dev/null 2>&1
fi

# Install Bun
if ! command -v bun &> /dev/null; then
    log_info "Installing Bun package manager..."
    curl -fsSL https://bun.sh/install | bash
    export PATH="$HOME/.bun/bin:$PATH"
fi

# Add Bun to PATH for current session
export PATH="$HOME/.bun/bin:$PATH"

# Install QMD CLI via npm (Bun version has issues with binary detection)
if ! command -v qmd &> /dev/null; then
    log_info "Installing QMD CLI..."
    npm install -g @tobilu/qmd > /dev/null 2>&1 || log_warn "QMD installation failed (may need manual install)"
else
    log_info "QMD already installed"
fi

# Create QMD collection for OpenClaw workspace
if command -v qmd &> /dev/null; then
    log_info "Creating QMD collection for OpenClaw workspace..."
    # Check if collection already exists
    if ! qmd collection list 2>/dev/null | grep -q "openclaw-main"; then
        qmd collection add "$HOME/.openclaw/workspace" --name openclaw-main --mask "**/*.md" --chunk 900 --overlap 0.15 > /dev/null 2>&1 || log_warn "QMD collection creation failed"
        log_info "QMD collection 'openclaw-main' created"
    else
        log_info "QMD collection 'openclaw-main' already exists"
    fi

    # Update BM25 index (no embeddings needed for basic search)
    log_info "Updating QMD BM25 index..."
    qmd update > /dev/null 2>&1 || log_warn "QMD index update failed"

    QMD_VERSION=$(qmd --version 2>/dev/null || echo "unknown")
    log_info "QMD version: $QMD_VERSION"
else
    log_warn "QMD not available, skipping collection setup"
fi

# Step 8: Start services
log_info "Step 8: Starting services..."

# Reload systemd daemon
systemctl --user daemon-reload

# Enable linger for user services
loginctl enable-linger $USER

# Start cloudflared (system service)
systemctl start cloudflared

# Start OpenClaw gateway (user service)
systemctl --user start openclaw-gateway
systemctl --user enable openclaw-gateway

# Step 9: Verify
log_info "Step 9: Verifying installation..."
sleep 5

echo ""
echo "=== Service Status ==="
systemctl --user status openclaw-gateway --no-pager || true
systemctl status cloudflared --no-pager || true

echo ""
echo "=== Webhook Test ==="
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://127.0.0.1:18789/webhook/line/default || echo "Webhook not responding"

echo ""
echo "=========================================="
log_info "Restoration complete!"
echo "=========================================="
echo ""
echo "External URL: https://openclaw.deskrex.ai"
echo "LINE Bot ID: @785sznop (OpenRex)"
echo ""
echo "To check logs:"
echo "  journalctl --user -u openclaw-gateway -f"
echo ""
echo "To restart gateway:"
echo "  systemctl --user restart openclaw-gateway"
