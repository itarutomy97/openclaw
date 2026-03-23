# CLAUDE.md

OpenClaw AI Gatewayのマルチインスタンス管理リポジトリ。

## Architecture

```
openclaw/
├── xserver/                    # XServer VPSインスタンス (162.43.54.40)
│   ├── openclaw.json           # Main-LINE: LINE only (port 18789)
│   ├── openclaw-slack.json     # Main-Slack: Slack only (port 18830)
│   ├── openclaw-telegram.json  # Main-Telegram: Telegram only (port 18840)
│   ├── openclaw-alpha.json     # Alpha: Discord 常識役 (port 18791)
│   ├── openclaw-beta.json      # Beta: Discord 実行役 (port 18790)
│   ├── openclaw-sudax.json     # Sudax: Discord スダックス (port 18800)
│   ├── openclaw-tight.json     # Tight: Discord タイトさん (port 18810)
│   ├── openclaw-onagigawa.json # Onagigawa: Discord おなぎの翁 (port 18820)
│   ├── .env.backup             # APIキーバックアップ
│   ├── soul/                   # SOUL.md（Bot人格・ループ防止ルール）
│   ├── cron/                   # cronジョブ設定バックアップ（{instance}-jobs.json）
│   ├── config/                 # systemdサービステンプレート
│   └── scripts/                # 管理スクリプト
├── patches/                    # 共通パッチ（全インスタンス共通）
└── docs/                       # 共通ドキュメント
```

### 8-Instance Architecture

| Instance | Port | Channel | Role | State Dir | Workspace |
|----------|------|---------|------|-----------|-----------|
| Main-LINE | 18789 | LINE only | 汎用（LINE） | `~/.openclaw/` | `~/.openclaw/workspace` |
| Main-Slack | 18830 | Slack only | 汎用（Slack） | `~/.openclaw-slack/` | `~/.openclaw/workspace-slack` |
| Main-Telegram | 18840 | Telegram only | 汎用（Telegram） | `~/.openclaw-telegram/` | `~/.openclaw/workspace-telegram` |
| Alpha | 18791 | Discord only | 常識役（参謀） | `~/.openclaw-alpha/` | `~/.openclaw/workspace-alpha` |
| Beta | 18790 | Discord only | 実行役 | `~/.openclaw-beta/` | `~/.openclaw/workspace-beta` |
| Sudax | 18800 | Discord only | スダックス persona | `~/.openclaw-sudax/` | `~/.openclaw/workspace-sudax` |
| Tight | 18810 | Discord only | タイトさん persona | `~/.openclaw-tight/` | `~/.openclaw/workspace-tight` |
| Onagigawa | 18820 | Discord only | おなぎの翁 persona | `~/.openclaw-onagigawa/` | `~/.openclaw/workspace-onagigawa` |

Main-LINE は Cloudflare Tunnel (`https://openclaw.deskrex.ai`) 経由で LINE webhook を受信。Main-Slack は Socket Mode（WebSocket）、Main-Telegram は polling で接続するため Tunnel 不要。

Alpha と Beta は Discord 上で同じチャンネル (1484094170648805397) に参加。Sudax/Tight/Onagigawa は別チャンネル (1484387071790678067) に参加。各インスタンスは独立したメモリ・人格を持つ。Onagigawa は requireMention: false（メンション不要で反応）。

### Bot間通信設定

- `allowBots: true` - Bot同士の会話を有効化（v2026.3.2は"mentions"未対応）
- Bot間メンションは `<@ユーザーID>` 形式で行う（テキスト "@BotB" では反応しない）
- 各BotのSOUL.md (`xserver/soul/`) にループ防止ルール・相手BotのIDテーブルを定義
- スレッド内では初回メンション後、以降はメンション不要で会話継続可能

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

# Service management (all 8 instances)
systemctl --user status openclaw-gateway.service             # Main-LINE
systemctl --user status openclaw-gateway-slack.service       # Main-Slack
systemctl --user status openclaw-gateway-telegram.service    # Main-Telegram
systemctl --user status openclaw-gateway-alpha.service       # Alpha
systemctl --user status openclaw-gateway-beta.service        # Beta
systemctl --user status openclaw-gateway-sudax.service       # Sudax
systemctl --user status openclaw-gateway-tight.service       # Tight
systemctl --user status openclaw-gateway-onagigawa.service   # Onagigawa
systemctl --user restart openclaw-gateway.service
systemctl status cloudflared

# Logs
journalctl --user -u openclaw-gateway.service -f             # Main-LINE
journalctl --user -u openclaw-gateway-slack.service -f       # Main-Slack
journalctl --user -u openclaw-gateway-telegram.service -f    # Main-Telegram
journalctl --user -u openclaw-gateway-alpha.service -f       # Alpha
journalctl --user -u openclaw-gateway-beta.service -f        # Beta
journalctl --user -u openclaw-gateway-sudax.service -f       # Sudax
journalctl --user -u openclaw-gateway-tight.service -f       # Tight
journalctl --user -u openclaw-gateway-onagigawa.service -f   # Onagigawa

# Diagnostics
openclaw status --all
openclaw doctor
```

### Scripts

```
xserver/scripts/
├── restore-vps.sh       # Full VPS restoration after rebuild
├── deploy-workspace.sh  # Deploy SOUL.md/AGENTS.md/etc to correct workspace paths
├── apply-line-patch.sh  # Fix LINE restart loop bug
├── auto-line-patch.sh   # Auto-patch on service start
├── health-check.sh      # Verify configuration integrity
└── sync-config.sh       # Restore settings from backup
```

### Workspace分離（超重要）

各インスタンスは `OPENCLAW_PROFILE` で workspace を分離する。

| Instance | OPENCLAW_PROFILE | Workspace Path | Soul Prefix |
|----------|-----------------|----------------|-------------|
| Main-LINE | (なし) | `~/.openclaw/workspace` | `main-line-` |
| Main-Slack | slack | `~/.openclaw/workspace-slack` | `main-slack-` |
| Main-Telegram | telegram | `~/.openclaw/workspace-telegram` | `main-telegram-` |
| Alpha | alpha | `~/.openclaw/workspace-alpha` | `alpha-` |
| Beta | beta | `~/.openclaw/workspace-beta` | `beta-` |
| Sudax | sudax | `~/.openclaw/workspace-sudax` | `sudax-` |
| Tight | tight | `~/.openclaw/workspace-tight` | `tight-` |
| Onagigawa | onagigawa | `~/.openclaw/workspace-onagigawa` | `onagigawa-` |

**絶対にやってはいけないこと:**
- `~/.openclaw/workspace`（Main）にDiscord Bot用のSOUL.mdを置くこと → 全Botが同じpersonaを読む
- `~/.openclaw-{profile}/workspace` にファイルを置くこと → PROFILEモードでは読まれない
- workspaceファイルの更新時にセッションをクリアし忘れること → 古いpersonaが残る

**workspaceファイル更新手順:** `./xserver/scripts/deploy-workspace.sh [instance|all]`

**ローカルでの管理:** `xserver/soul/` に `{instance}-{FILE}.md` 形式で保管（gitバックアップ）

### Hard Rules

- **After `npm update -g openclaw`**: Run `./xserver/scripts/sync-config.sh`（全インスタンスを再起動。LINE パッチは ExecStartPre で自動適用）
- **After VPS rebuild**: Use `./xserver/scripts/restore-vps.sh`
- **OPENCLAW_PROFILE**: 各Discord Botのsystemdサービスに `OPENCLAW_PROFILE={instance}` が必須（workspace分離のため）
- **Workspace deploy**: SOUL.md等を更新したら必ず `deploy-workspace.sh` を使う（手動cpは禁止 → パスミス防止）
- **Session clear**: workspace更新後は必ずセッション削除 → `rm -rf ~/.openclaw-*/agents/*/sessions/*`
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
- **Discord Bot Onagigawa**: おなぎの翁 (小名木川 persona, client_id: 1484475707097878528) - Onagigawa instance
- **Discord Server**: 1473906830160953548
- **Cloudflare Tunnel**: openclaw.deskrex.ai
- **Brave Search API**: キー in `xserver/.env.backup`、全インスタンスの `.env` に設定済み
- **Tavily Search API**: `openclaw-tavily` プラグイン (search/extract/crawl/research/map)、キー in `xserver/.env.backup`、全インスタンスの `.env` に設定済み
- **Camofox Browser**: `@askjo/camofox-browser@1.4.0` (ブラウザ自動化プラグイン、全インスタンス共通)
- **QMD**: `@tobilu/qmd` (Markdown ドキュメント検索、BM25 インデックス)
- **Dashboard Token**: In `xserver/.env.backup` / `xserver/openclaw.json`
