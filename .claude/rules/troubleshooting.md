# Troubleshooting

## Gateway Won't Start

```bash
# Check logs
journalctl --user -u openclaw-gateway.service --no-pager -n 30

# Test manual start
openclaw gateway --port 18789
```

## LINE Restart Loop

Symptom: Gateway continuously restarts LINE channel.

Fix:
```bash
./xserver/scripts/apply-line-patch.sh
systemctl --user restart openclaw-gateway.service
```

Root cause: OpenClaw v2026.2.17's LINE webhook provider resolves immediately, gateway interprets this as "channel stopped".

## Z.ai API Errors

```bash
# Verify API key in .env file
grep ZAI_API_KEY ~/.openclaw/.env

# Re-add if missing
echo "ZAI_API_KEY=YOUR_KEY" >> ~/.openclaw/.env
systemctl --user restart openclaw-gateway.service

# Or restore from backup
./scripts/sync-config.sh
```

## Pairing Error (disconnected 1008: pairing required)

Cause: `trustedProxies` only allows localhost, Cloudflare requests are "untrusted".

### Option 1: Approve pairing (temporary)

```bash
openclaw devices list
openclaw devices approve <REQUEST_ID>
```

### Option 2: Add Cloudflare IPs to trustedProxies (permanent)

Edit `~/.openclaw/openclaw.json`:

```json
"gateway": {
  "trustedProxies": [
    "127.0.0.1",
    "::1",
    "173.245.48.0/20",
    "103.21.244.0/22",
    "103.22.200.0/22",
    "103.31.4.0/22",
    "141.101.64.0/18",
    "108.162.192.0/18",
    "190.93.240.0/20",
    "188.114.96.0/20",
    "197.234.240.0/22",
    "198.41.128.0/17",
    "162.158.0.0/15",
    "104.16.0.0/13",
    "104.24.0.0/14",
    "172.64.0.0/13",
    "131.0.72.0/22"
  ]
}
```

Then restart: `systemctl --user restart openclaw-gateway.service`

## Cloudflare Tunnel Down

```bash
systemctl status cloudflared
systemctl restart cloudflared
```

## Config Lost After Update

```bash
./xserver/scripts/sync-config.sh
```
