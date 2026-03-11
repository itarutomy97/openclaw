# VPS Operations

## Full Restoration (After VPS Rebuild)

1. Transfer files to VPS:
```bash
scp -r openclaw-x-server root@162.43.54.40:/tmp/
```

2. SSH and run restore script:
```bash
ssh root@162.43.54.40
cd /tmp/openclaw-x-server
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
./scripts/apply-line-patch.sh   # Fix LINE restart loop
./scripts/sync-config.sh         # Restore credentials
```

## Health Check

Run periodically or after any changes:

```bash
/root/openclaw-x-server/scripts/health-check.sh
```

Checks:
- ZAI_API_KEY presence
- LINE credentials in openclaw.json
- Gateway service running
- Cloudflare tunnel running
- Recent errors in logs

## Configuration Sync

If settings are missing or corrupted:

```bash
./scripts/sync-config.sh
```

Restores:
- openclaw.json → ~/.openclaw/
- Environment variables → ~/.openclaw/.env
- Restarts gateway service

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
