# CLAUDE.md

OpenClaw AI Gatewayのマルチインスタンス管理リポジトリ。

## Architecture

```
openclaw/
├── xserver/               # XServer VPSインスタンス (162.43.54.40)
│   ├── openclaw.json      # モデル、LINE/Slack認証、Gateway設定
│   ├── .env.backup        # APIキーバックアップ
│   ├── config/            # systemdサービステンプレート
│   └── scripts/           # 管理スクリプト
├── patches/               # 共通パッチ（全インスタンス共通）
└── docs/                  # 共通ドキュメント
```

新しいインスタンスを追加する場合は `xserver/` と同レベルにディレクトリを作成。

## XServer Instance

| Item | Value |
|------|-------|
| IP | 162.43.54.40 |
| User | root (password in `xserver/.password`) |
| External | https://openclaw.deskrex.ai |
| Tech | Ubuntu 24.04 LTS, Node.js 24 (NVM), OpenClaw, Z.ai GLM-5, systemd, Cloudflare Tunnel |

### Commands

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
openclaw dashboard
```

### Scripts

```
xserver/scripts/
├── restore-vps.sh      # Full VPS restoration after rebuild
├── apply-line-patch.sh  # Fix LINE restart loop bug
├── auto-line-patch.sh   # Auto-patch on service start
├── health-check.sh      # Verify configuration integrity
└── sync-config.sh       # Restore settings from backup
```

### Hard Rules

- **After `npm update -g openclaw`**: MUST run `./xserver/scripts/apply-line-patch.sh` and `./xserver/scripts/sync-config.sh`
- **After VPS rebuild**: Use `./xserver/scripts/restore-vps.sh`
- **ZAI_API_KEY**: Must be in systemd service file, NOT openclaw.json
- **LINE patch**: Required for v2026.2.17 - webhook provider resolves immediately causing restart loops

## Quick Links (Rules)

| Rule File | Content |
|----------|---------|
| `vps-operations.md` | Restoration procedures, health checks, post-update steps |
| `troubleshooting.md` | Common issues: pairing errors, restart loops, API errors |

## External Services

- **LINE Bot**: @785sznop (OpenRex)
- **Cloudflare Tunnel**: openclaw.deskrex.ai
- **Dashboard Token**: In `xserver/.env.backup` / `xserver/openclaw.json`
