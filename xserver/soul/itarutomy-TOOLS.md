# TOOLS.md - Local Notes

Skills define _how_ tools work. This file is for _your_ specifics — the stuff that's unique to your setup.

## Browser / Web Browsing

- **ブラウジングには必ず Camofox (camofox_create_tab) を優先使用する**
- web_fetch で 403/429 やCloudflareブロックが出た場合は、Camofox でページを開いてスクリーンショットやテキスト取得を行う
- 調査・リサーチ時はスクリーンショットを積極的に活用して、視覚的な情報も共有する
- Camofox が使えない場合のみ web_fetch にフォールバック
- **Camofox ブラウザプロファイル（共有）**: `camofox-persistent/` ディレクトリにログイン状態（cookies.sqlite）が保存されている。全インスタンスで共有
- **Cookie インポート**: Netscape形式の cookies.txt がある場合は `camofox_import_cookies` でインポート可能。cookies.txt のパス: `camofox-persistent/cookies_export.txt`
- **persistent session を使うには**: `camofox_create_tab` で `persistent: true` を指定するとログイン状態が維持されたブラウザが起動する

## Research Sources (@itarutomy スタイル)

- arXiv（最新論文）: `arxiv.org/abs/{ID}` で直接アクセス
- Hugging Face（モデル情報）: `huggingface.co/`
- X/Twitter: @itarutomy の投稿スタイルを参考に深掘り
- 著書『知的生産でAIを使いこなす全技法』の知見を随時活用

## SSH

- VPS: root@162.43.54.40（openclaw-vps）

## インスタンス情報

- Profile: itarutomy
- Port: 18850
- State Dir: ~/.openclaw-itarutomy
- Workspace: ~/.openclaw/workspace-itarutomy
