# CLAUDE.md

OpenClaw AI Gateway VPS configuration for DeskRex platform. LINE/Slack integration via Cloudflare Tunnel.

## Tech Stack

Ubuntu 24.04 LTS | Node.js 24 (NVM) | OpenClaw 2026.2.17 | Z.ai GLM-5 | systemd | Cloudflare Tunnel

## Server

| Item | Value |
|------|-------|
| IP | 162.43.54.40 |
| User | root (password in `.password`) |
| External | https://openclaw.deskrex.ai |
| Local | http://localhost:18789 (via SSH tunnel) |

## Commands

```bash
# SSH connection
ssh root@162.43.54.40

# Dashboard tunnel (access localhost:18789 in browser)
ssh -N -L 18789:127.0.0.1:18789 root@162.43.54.40

# Service management
systemctl --user status openclaw-gateway.service
systemctl --user restart openclaw-gateway.service
systemctl status cloudflared

# Logs
journalctl --user -u openclaw-gateway.service -f
openclaw logs

# Diagnostics
openclaw status --all
openclaw doctor
openclaw dashboard  # Get URL with auth token
```

## Scripts

```
scripts/
├── restore-vps.sh      # Full VPS restoration after rebuild
├── apply-line-patch.sh # Fix LINE restart loop bug
├── health-check.sh     # Verify configuration integrity
└── sync-config.sh      # Restore settings from backup
```

## Hard Rules

- **After `npm update -g openclaw`**: MUST run `./scripts/apply-line-patch.sh` and `./scripts/sync-config.sh`
- **After VPS rebuild**: Use `./scripts/restore-vps.sh`
- **ZAI_API_KEY**: Must be in systemd service file, NOT openclaw.json
- **LINE patch**: Required for v2026.2.17 - webhook provider resolves immediately causing restart loops

## Repository Structure

```
openclaw-x-server/
├── openclaw.json           # Model, LINE/Slack credentials, gateway config
├── .env.backup             # API keys backup
├── config/                 # systemd service templates
├── patches/                # LINE webhook fix patch
└── scripts/                # Management scripts
```

## Quick Links (Rules)

| Rule File | Content |
|----------|---------|
| `vps-operations.md` | Restoration procedures, health checks, post-update steps |
| `troubleshooting.md` | Common issues: pairing errors, restart loops, API errors |

## External Services

- **LINE Bot**: @785sznop (OpenRex)
- **Cloudflare Tunnel**: openclaw.deskrex.ai
- **Dashboard Token**: In `.env.backup` / `openclaw.json`
