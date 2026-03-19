# OpenClaw

OpenClaw AI Gatewayのマルチインスタンス管理リポジトリ。

## Instances

| インスタンス | サーバー | 説明 |
|-------------|---------|------|
| [xserver/](./xserver/) | 162.43.54.40 | XServer VPS (LINE/Slack/Telegram) |

## 共通リソース

- `patches/` - 全インスタンスで使えるパッチファイル
- `docs/` - 共通ドキュメント

## 新しいインスタンスの追加

`xserver/` と同レベルにディレクトリを作成し、インスタンス固有の設定・スクリプトを配置してください。

```
openclaw/
├── xserver/          # 既存
├── new-server/       # 新規インスタンス
│   ├── openclaw.json
│   ├── config/
│   └── scripts/
├── patches/
└── docs/
```
