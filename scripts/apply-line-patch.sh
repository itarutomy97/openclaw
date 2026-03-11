#!/bin/bash
# apply-line-patch.sh
# Apply the LINE restart loop fix patch to OpenClaw
#
# Usage: ./apply-line-patch.sh [openclaw-install-path]
#
# Default path: /root/.nvm/versions/node/v24.13.1/lib/node_modules/openclaw

set -e

OPENCLAW_PATH="${1:-/root/.nvm/versions/node/v24.13.1/lib/node_modules/openclaw}"
CHANNEL_FILE="$OPENCLAW_PATH/extensions/line/src/channel.ts"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== OpenClaw LINE Restart Loop Fix ==="
echo "Target file: $CHANNEL_FILE"

# Check if file exists
if [ ! -f "$CHANNEL_FILE" ]; then
    echo "ERROR: channel.ts not found at $CHANNEL_FILE"
    echo "Make sure OpenClaw is installed and provide the correct path"
    exit 1
fi

# Check if patch is already applied
if grep -q "Keep the channel alive until abort signal fires" "$CHANNEL_FILE"; then
    echo "Patch already applied. Nothing to do."
    exit 0
fi

# Find the line with "return monitor;" after monitorLineProvider
LINE_NUM=$(grep -n "return monitor;" "$CHANNEL_FILE" | head -1 | cut -d: -f1)

if [ -z "$LINE_NUM" ]; then
    echo "ERROR: Could not find 'return monitor;' line"
    exit 1
fi

# Find the context - should be after monitorLineProvider call
CONTEXT_LINE=$(sed -n "$((LINE_NUM-5)),$((LINE_NUM))p" "$CHANNEL_FILE")

if ! echo "$CONTEXT_LINE" | grep -q "monitorLineProvider"; then
    echo "ERROR: 'return monitor;' found but not after monitorLineProvider"
    exit 1
fi

echo "Found insertion point at line $LINE_NUM"

# Create backup
cp "$CHANNEL_FILE" "$CHANNEL_FILE.bak"
echo "Backup created: $CHANNEL_FILE.bak"

# Insert the patch code before "return monitor;"
# The patch code to insert (with proper indentation)
PATCH_CODE='
      // Keep the channel alive until abort signal fires (webhook provider fix)
      await new Promise<void>((resolve) => {
        if (ctx.abortSignal?.aborted) { resolve(); return; }
        ctx.abortSignal?.addEventListener("abort", () => resolve(), { once: true });
      });
'

# Use sed to insert the patch
sed -i "${LINE_NUM}i\\
${PATCH_CODE}" "$CHANNEL_FILE"

echo "Patch applied successfully!"
echo ""
echo "To verify, run:"
echo "  sed -n '665,675p' $CHANNEL_FILE"
echo ""
echo "To undo:"
echo "  mv $CHANNEL_FILE.bak $CHANNEL_FILE"
