# OpenClaw XServer VPS

## サーバー情報

| 項目 | 値 |
|------|-----|
| サーバー名 | openclaw-x-server-vps |
| IPアドレス | 162.43.54.40 |
| ユーザー | root |
| SSHポート | 22 |
| OS | Ubuntu 24.04 LTS |
| OpenClaw | 2026.2.22-2 |
| モデル | Z.ai GLM-5 |
| 外部アクセス | Cloudflare Access保護（要ログイン） |

## 接続方法

### パスワード認証（推奨）

```bash
ssh root@162.43.54.40
# パスワード: .passwordファイルを参照
```

### SSH Config設定後

```bash
ssh openclaw-vps
```

## SSH Config設定

`~/.ssh/config` に以下を追加：

```
Host openclaw-vps
    HostName 162.43.54.40
    User root
    Port 22
    # PEM鍵は未登録のためパスワード認証を使用

# ダッシュボード用トンネル
Host openclaw-vps-tunnel
    HostName 162.43.54.40
    User root
    Port 22
    LocalForward 18789 127.0.0.1:18789
```

---

## 復旧手順（サーバー障害時）

VPSが再構築された場合、以下の手順で復旧できます。

### 必要なファイル

```
openclaw-x-server/
├── openclaw.json           # OpenClaw設定（モデル、LINE認証など）
├── .env.backup             # 環境変数（APIキー、トークン）
├── config/
│   ├── cloudflared.service # Cloudflareトンネル設定
│   └── openclaw-gateway.service # systemdサービス設定
├── patches/
│   └── line-restart-fix.patch # LINEリスタートループ修正パッチ
└── scripts/
    ├── restore-vps.sh      # 完全復旧スクリプト
    ├── apply-line-patch.sh # パッチ適用スクリプト（旧式）
    └── auto-line-patch.sh  # 自動パッチスクリプト（systemdで実行）
```

### 自動復旧（推奨）

```bash
# VPSにファイル一式を転送
scp -r openclaw-x-server root@162.43.54.40:/tmp/

# SSHでログイン
ssh root@162.43.54.40

# 復旧スクリプト実行
cd /tmp/openclaw-x-server
chmod +x scripts/*.sh
./scripts/restore-vps.sh
```

### 手動復旧

1. **Node.js インストール**
   ```bash
   curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
   source ~/.bashrc
   nvm install 24
   nvm use 24
   ```

2. **OpenClaw インストール**
   ```bash
   npm install -g openclaw
   ```

3. **設定ファイル配置**
   ```bash
   mkdir -p ~/.openclaw
   cp openclaw.json ~/.openclaw/openclaw.json
   ```

4. **Gateway サービスインストール**
   ```bash
   openclaw gateway install --port 18789
   ```

5. **ZAI_API_KEY 追加**
   ```bash
   # ~/.config/systemd/user/openclaw-gateway.service に追加
   Environment=ZAI_API_KEY=d8179e04264a4ab9add1a08e60481372.EpG4UtsMwtyILuEK
   ```

6. **LINE パッチ適用**
   ```bash
   ./scripts/apply-line-patch.sh
   ```

7. **Cloudflare トンネル設定**
   ```bash
   curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
   dpkg -i cloudflared.deb
   cp config/cloudflared.service /etc/systemd/system/
   systemctl daemon-reload
   systemctl enable --now cloudflared
   ```

8. **サービス起動**
   ```bash
   loginctl enable-linger $USER
   systemctl --user daemon-reload
   systemctl --user enable --now openclaw-gateway
   ```

---

## OpenClawコマンド

```bash
# 状態確認
openclaw status --all

# システム診断
openclaw doctor

# ダッシュボードURL取得（トークン付き）
openclaw dashboard

# ログ確認
openclaw logs

# Gatewayサービス操作
systemctl --user status openclaw-gateway.service
systemctl --user restart openclaw-gateway.service
systemctl --user stop openclaw-gateway.service
```

## 外部アクセス

| URL | 説明 |
|-----|------|
| https://openclaw.deskrex.ai | Cloudflare Access保護（要Googleログイン） |
| http://localhost:18789 | SSHトンネル経由（ローカルのみ） |

### Cloudflare Access設定

OpenClaw Control UIはCloudflare Accessで保護されています。

| 設定 | 値 |
|------|-----|
| アプリケーション | OpenClaw |
| ドメイン | openclaw.deskrex.ai |
| 認証方法 | Google OAuth |
| 許可メール | tomtar9779@gmail.com |
| BYPASSパス | /line/webhook (LINE Bot用) |

**注意**: LINE webhookパスはBYPASS設定が必要（LINEサーバーからのアクセスのため）。

## ダッシュボード接続（Web UI）

### 手順1: トンネル作成

```bash
# 新しいターミナルで実行
ssh -N -L 18789:127.0.0.1:18789 root@162.43.54.40
```

### 手順2: ブラウザでアクセス

| URL | 説明 |
|-----|------|
| http://localhost:18789/ | 通常アクセス |
| http://localhost:18789/#token=1683852b3d25052da0dca5cb144d3a91ced25d3282b4cc89 | トークン認証付き |

---

## モデル設定（GLM-5 / Z.ai）

OpenClawはZ.aiのGLM-5をデフォルトモデルとして使用します。

### 設定内容（openclaw.json）

```json
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "zai/glm-5"
      }
    }
  }
}
```

### ZAI_API_KEY 設定

systemdサービスに環境変数として設定：

```
Environment=ZAI_API_KEY=d8179e04264a4ab9add1a08e60481372.EpG4UtsMwtyILuEK
```

**注意**: `openclaw gateway install` を実行するとサービスファイルが再生成されるため、ZAI_API_KEYを再追加する必要があります。

---

## チャンネル設定

### Telegram Bot

| 項目 | 値 |
|------|-----|
| Bot | @openrex_bot |
| 設定 | `channels.telegram.botToken` in openclaw.json |
| 環境変数 | `TELEGRAM_BOT_TOKEN` |

### Slack App

| 項目 | 値 |
|------|-----|
| App ID | A0AG7UDV57D |
| 設定 | `channels.slack.*` in openclaw.json |
| 環境変数 | `OPENCLAW_SLACK_BOT_TOKEN`, `OPENCLAW_SLACK_APP_TOKEN`, `OPENCLAW_SLACK_SIGNING_SECRET` |

### LINE Bot

| 項目 | 値 |
|------|-----|
| Bot名 | OpenRex |
| Basic ID | @785sznop |
| Channel ID | 2009139035 |
| Webhook URL | https://openclaw.deskrex.ai/line/webhook |
| 環境変数 | `LINE_CHANNEL_ACCESS_TOKEN`, `LINE_CHANNEL_SECRET` |

### LINE リスタートループ修正パッチ

**問題**: OpenClaw v2026.2.17のLINE拡張は、webhookベースのためGatewayが「チャンネル停止」と誤検知し、再起動ループに陥る。

**修正**: `extensions/line/src/channel.ts` にabort signal待機コードを追加。

```typescript
// 669行目以降に追加
// Keep the channel alive until abort signal fires (webhook provider fix)
await new Promise<void>((resolve) => {
  if (ctx.abortSignal?.aborted) { resolve(); return; }
  ctx.abortSignal?.addEventListener("abort", () => resolve(), { once: true });
});
```

### 自動パッチ適用システム（npm update対応）

**仕組み**: systemdサービスの`ExecStartPre`でパッチスクリプトを自動実行。`npm update -g openclaw`でパッチが消えても、次回起動時に自動再適用される。

```
/root/openclaw-scripts/auto-line-patch.sh  # パッチスクリプト
~/.config/systemd/user/openclaw-gateway.service  # ExecStartPreで呼び出し
```

**注意**: `npm update -g openclaw` でパッチが消えるため、更新後に再適用が必要。

---

## 再発防止策

### 自動ヘルスチェック

毎時自動でヘルスチェックが実行され、設定の欠損を検出します。

```bash
# 手動実行
/root/openclaw-x-server/scripts/health-check.sh

# ログ確認
tail -f /var/log/openclaw-health.log
```

### 設定復元（ワンコマンド）

設定が消えた場合、以下で復元：

```bash
/root/openclaw-x-server/scripts/sync-config.sh
```

### 注意: OpenClaw更新後

`npm update -g openclaw` 実行後は、サービスを再起動するだけでOK（パッチは自動適用）：

```bash
systemctl --user restart openclaw-gateway.service
```

※ LINEパッチはExecStartPreで自動適用されるため手動不要

---

## トラブルシューティング

### Gatewayが起動しない場合

```bash
# ログ確認
journalctl --user -u openclaw-gateway.service --no-pager -n 30

# 手動起動テスト
openclaw gateway --port 18789
```

### LINEリスタートループが発生した場合

```bash
# パッチ再適用
./scripts/apply-line-patch.sh

# Gateway再起動
systemctl --user restart openclaw-gateway.service
```

### Z.ai APIエラーが発生した場合

```bash
# ZAI_API_KEY確認
grep ZAI_API_KEY ~/.config/systemd/user/openclaw-gateway.service

# 再追加（必要な場合）
sed -i '/Environment=OPENCLAW_SERVICE_VERSION/a Environment=ZAI_API_KEY=YOUR_KEY' ~/.config/systemd/user/openclaw-gateway.service
systemctl --user daemon-reload
systemctl --user restart openclaw-gateway.service
```

### ペアリングエラー（disconnected 1008: pairing required）

Cloudflare Tunnel経由でアクセスすると、新しいブラウザ/デバイスから接続するたびにペアリングが必要になる。

**原因**: `trustedProxies` が localhost のみ許可しているため、Cloudflare経由のリクエストが「信頼できないプロキシ」と判断される。

**解決方法（2通り）**:

#### 方法1: ペアリングを承認（都度必要）

```bash
# 保留中のペアリングを確認
openclaw devices list

# 承認（Request IDを指定）
openclaw devices approve <REQUEST_ID>

# 例: openclaw devices approve 405c0c40-f29f-442f-9c00-b85624c9ce98
```

ブラウザをリロードすれば接続できる。

#### 方法2: trustedProxies に Cloudflare IP 範囲を追加（根本解決）

`~/.openclaw/openclaw.json` の gateway 設定を更新:

```json
"gateway": {
  "port": 18789,
  "mode": "local",
  "auth": {
    "mode": "none"
  },
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

設定変更後はGateway再起動:
```bash
systemctl --user restart openclaw-gateway.service
```

**注意**: 一時的な回避策として `"0.0.0.0/0"` も使えるが、セキュリティリスクがあるため非推奨。

### Cloudflareトンネルエラー

```bash
# サービス状態確認
systemctl status cloudflared

# 再起動
systemctl restart cloudflared
```

---

## 参考リンク

- [OpenClaw公式サイト](https://openclaw.ai/)
- [OpenClawドキュメント](https://docs.openclaw.ai/)
- [Z.ai API](https://z.ai/)
