# CLAUDE.md

OpenClaw AI Gatewayのマルチインスタンス管理リポジトリ。

## Architecture

```
openclaw/
├── xserver/                    # XServer VPSインスタンス (162.43.54.40)
│   ├── openclaw.json           # Main: LINE/Slack/Telegram (port 18789)
│   ├── openclaw-alpha.json     # Alpha: Discord 常識役 (port 18791)
│   ├── openclaw-bot2.json      # Beta: Discord 実行役 (port 18790)
│   ├── .env.backup             # APIキーバックアップ
│   ├── config/                 # systemdサービステンプレート
│   └── scripts/                # 管理スクリプト
├── patches/                    # 共通パッチ（全インスタンス共通）
└── docs/                       # 共通ドキュメント
```

### 3-Instance Architecture

| Instance | Port | Channels | Role | State Dir |
|----------|------|----------|------|-----------|
| Main | 18789 | LINE, Slack, Telegram | 汎用 | `~/.openclaw/` |
| Alpha | 18791 | Discord only | 常識役（参謀） | `~/.openclaw-alpha/` |
| Beta | 18790 | Discord only | 実行役 | `~/.openclaw-bot2/` |
| Sudax | 18800 | Discord only | スダックス persona | `~/.openclaw-sudax/` |
| Tight | 18810 | Discord only | タイトさん persona | `~/.openclaw-tight/` |

Alpha と Beta は Discord 上で同じチャンネルに参加し、独立したメモリ・人格を持つ。Sudax/Tight は別チャンネル用。各インスタンスの SOUL.md / AGENTS.md で役割を定義。

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

# Service management (all 3 instances)
systemctl --user status openclaw-gateway.service          # Main
systemctl --user status openclaw-gateway-alpha.service    # Alpha
systemctl --user status openclaw-gateway-bot2.service     # Beta
systemctl --user status openclaw-gateway-sudax.service    # Sudax
systemctl --user status openclaw-gateway-tight.service    # Tight
systemctl --user restart openclaw-gateway.service
systemctl status cloudflared

# Logs
journalctl --user -u openclaw-gateway.service -f          # Main
journalctl --user -u openclaw-gateway-alpha.service -f    # Alpha
journalctl --user -u openclaw-gateway-bot2.service -f     # Beta
journalctl --user -u openclaw-gateway-sudax.service -f    # Sudax
journalctl --user -u openclaw-gateway-tight.service -f    # Tight

# Diagnostics
openclaw status --all
openclaw doctor
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

- **After `npm update -g openclaw`**: Run `./xserver/scripts/sync-config.sh`（全3インスタンスを再起動。LINE パッチは ExecStartPre で自動適用）
- **After VPS rebuild**: Use `./xserver/scripts/restore-vps.sh`
- **ZAI_API_KEY**: Must be in each instance's `.env`, NOT openclaw.json
- **OPENCLAW_STATE_DIR**: Alpha/Beta の独立は環境変数 `OPENCLAW_STATE_DIR` で実現（systemd service file で設定）
- **LINE patch**: Required for v2026.2.17+ - auto-line-patch.sh が ExecStartPre で毎起動時に自動適用
- **Health check**: `/root/openclaw/xserver/scripts/health-check.sh` が cron で毎時自動実行

## Quick Links (Rules)

| Rule File | Content |
|----------|---------|
| `vps-operations.md` | Restoration procedures, health checks, post-update steps |
| `troubleshooting.md` | Common issues: pairing errors, restart loops, API errors |

## External Services

- **LINE Bot**: @785sznop (OpenRex) - Main instance
- **Telegram Bot**: @openrex_bot - Main instance
- **Slack App**: A0AG7UDV57D (Socket Mode) - Main instance
- **Discord Bot Alpha**: OpenRex-alpha (常識役, client_id: 1484089242102661333) - Alpha instance
- **Discord Bot Beta**: OpenRex-beta (実行役, client_id: 1484094945735479367) - Beta instance
- **Discord Bot Sudax**: スダックス (須田仁之 persona, client_id: 1484401495439970515) - Sudax instance
- **Discord Bot Tight**: タイト (タイトさん/ユウキ persona, client_id: 1484404212136939580) - Tight instance
- **Discord Server**: 1473906830160953548
- **Cloudflare Tunnel**: openclaw.deskrex.ai
- **Brave Search API**: キー in `xserver/.env.backup`
- **Camofox Browser**: `@askjo/camofox-browser@1.4.0` (ブラウザ自動化プラグイン、全インスタンス共通)
- **QMD**: `@tobilu/qmd` (Markdown ドキュメント検索、BM25 インデックス)
- **Dashboard Token**: In `xserver/.env.backup` / `xserver/openclaw.json`
