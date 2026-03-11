#!/bin/bash
# Auto-apply LINE restart loop patch before OpenClaw starts
# This runs on every service start to ensure patch is always applied

CHANNEL_FILE="/root/.nvm/versions/node/v24.13.1/lib/node_modules/openclaw/extensions/line/src/channel.ts"

# Check if file exists (OpenClaw installed)
if [ ! -f "$CHANNEL_FILE" ]; then
    echo "OpenClaw LINE channel file not found, skipping patch"
    exit 0
fi

# Check if patch already applied
if grep -q "Keep the channel alive until abort signal fires" "$CHANNEL_FILE"; then
    echo "LINE patch already applied"
    exit 0
fi

echo "Applying LINE restart loop patch..."

# Use Python for reliable pattern replacement
python3 << 'PYEOF'
import re

file_path = "/root/.nvm/versions/node/v24.13.1/lib/node_modules/openclaw/extensions/line/src/channel.ts"

with open(file_path, 'r') as f:
    content = f.read()

old_pattern = r'''      return getLineRuntime\(\)\.channel\.line\.monitorLineProvider\(\{
        channelAccessToken: token,
        channelSecret: secret,
        accountId: account\.accountId,
        config: ctx\.cfg,
        runtime: ctx\.runtime,
        abortSignal: ctx\.abortSignal,
        webhookPath: account\.config\.webhookPath,
      \}\);'''

new_code = '''      const monitor = getLineRuntime().channel.line.monitorLineProvider({
        channelAccessToken: token,
        channelSecret: secret,
        accountId: account.accountId,
        config: ctx.cfg,
        runtime: ctx.runtime,
        abortSignal: ctx.abortSignal,
        webhookPath: account.config.webhookPath,
      });

      // Keep the channel alive until abort signal fires (webhook provider fix)
      await new Promise<void>((resolve) => {
        if (ctx.abortSignal?.aborted) { resolve(); return; }
        ctx.abortSignal?.addEventListener("abort", () => resolve(), { once: true });
      });

      return monitor;'''

new_content = re.sub(old_pattern, new_code, content)

if new_content != content:
    with open(file_path, 'w') as f:
        f.write(new_content)
    print("LINE patch applied successfully!")
else:
    print("Warning: Pattern not found, patch may need updating")
PYEOF

exit 0
