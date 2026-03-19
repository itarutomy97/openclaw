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
| Tech | Ubuntu 24.04 LTS, Node.js 24 (NVM), OpenClaw 2026.3.2, Z.ai GLM-4.7, Camofox Browser, QMD, systemd, Cloudflare Tunnel |

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

- **After `npm update -g openclaw`**: Run `./xserver/scripts/sync-config.sh` then `systemctl --user restart openclaw-gateway.service`（LINE パッチは ExecStartPre で自動適用）
- **After VPS rebuild**: Use `./xserver/scripts/restore-vps.sh`
- **ZAI_API_KEY**: Must be in `~/.openclaw/.env`, NOT openclaw.json（health-check.sh が .env を検証）
- **LINE patch**: Required for v2026.2.17+ - auto-line-patch.sh が ExecStartPre で毎起動時に自動適用
- **Health check**: `/root/openclaw/xserver/scripts/health-check.sh` が cron で毎時自動実行、ログは `/var/log/openclaw-health.log`

## Quick Links (Rules)

| Rule File | Content |
|----------|---------|
| `vps-operations.md` | Restoration procedures, health checks, post-update steps |
| `troubleshooting.md` | Common issues: pairing errors, restart loops, API errors |

## External Services

- **LINE Bot**: @785sznop (OpenRex)
- **Telegram Bot**: @openrex_bot
- **Slack App**: A0AG7UDV57D (Socket Mode)
- **Cloudflare Tunnel**: openclaw.deskrex.ai
- **Brave Search API**: キー in `xserver/.env.backup`
- **Camofox Browser**: `@askjo/camofox-browser@1.3.1` (ブラウザ自動化プラグイン)
- **QMD**: `@tobilu/qmd` (Markdown ドキュメント検索、BM25 インデックス)
- **Dashboard Token**: In `xserver/.env.backup` / `xserver/openclaw.json`
