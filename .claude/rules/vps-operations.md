# VPS Operations

## Full Restoration (After VPS Rebuild)

1. Transfer files to VPS:
```bash
scp -r openclaw/xserver root@162.43.54.40:/tmp/openclaw-xserver
```

2. SSH and run restore script:
```bash
ssh root@162.43.54.40
cd /tmp/openclaw-xserver
chmod +x scripts/*.sh
./scripts/restore-vps.sh
```

The script:
- Installs Node.js 24 via NVM
- Installs OpenClaw globally
- Copies openclaw.json to ~/.openclaw/
- Installs gateway service (port 18789)
- Adds ZAI_API_KEY to systemd service
- Applies LINE restart loop patch
- Configures Cloudflare tunnel
- Starts all services

## Post-OpenClaw Update

After running `npm update -g openclaw`:

```bash
./scripts/sync-config.sh         # Restore credentials (.env + openclaw.json)
systemctl --user restart openclaw-gateway.service  # LINE patch auto-applied via ExecStartPre
```

Note: LINE パッチは `auto-line-patch.sh` が ExecStartPre で自動適用するため手動不要。

## Health Check

Cron で毎時自動実行。手動でも実行可能：

```bash
/root/openclaw/xserver/scripts/health-check.sh

# ログ確認
tail -f /var/log/openclaw-health.log
```

Checks:
- ZAI_API_KEY presence in `~/.openclaw/.env`
- LINE credentials in openclaw.json
- Gateway service running
- Cloudflare tunnel running
- Recent errors in logs
- QMD CLI installed and openclaw-main collection status

## Configuration Sync

If settings are missing or corrupted:

```bash
./scripts/sync-config.sh
```

Restores:
- openclaw.json → ~/.openclaw/openclaw.json
- Environment variables → ~/.openclaw/.env (ZAI_API_KEY, Slack/LINE/Gateway tokens, Google credentials)
- Restarts gateway service (LINE patch auto-applied via ExecStartPre)

## SSH Config

Add to `~/.ssh/config`:

```
Host openclaw-vps
    HostName 162.43.54.40
    User root
    Port 22

Host openclaw-vps-tunnel
    HostName 162.43.54.40
    User root
    Port 22
    LocalForward 18789 127.0.0.1:18789
```
