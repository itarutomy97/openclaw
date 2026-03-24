# TOOLS.md - Local Notes

Skills define _how_ tools work. This file is for _your_ specifics — the stuff that's unique to your setup.

## What Goes Here

Things like:

- Camera names and locations
- SSH hosts and aliases
- Preferred voices for TTS
- Speaker/room names
- Device nicknames
- Anything environment-specific

## Examples

```markdown
### Cameras

- living-room → Main area, 180° wide angle
- front-door → Entrance, motion-triggered

### SSH

- home-server → 192.168.1.100, user: admin

### TTS

- Preferred voice: "Nova" (warm, slightly British)
- Default speaker: Kitchen HomePod
```

## Why Separate?

Skills are shared. Your setup is yours. Keeping them apart means you can update skills without losing your notes, and share skills without leaking your infrastructure.

---

Add whatever helps you do your job. This is your cheat sheet.


## Browser / Web Browsing

- **ブラウジングには必ず Camofox (camofox_create_tab) を優先使用する**
- web_fetch で 403/429 やCloudflareブロックが出た場合は、Camofox でページを開いてスクリーンショットやテキスト取得を行う
- 調査・リサーチ時はスクリーンショットを積極的に活用して、視覚的な情報も共有する
- Camofox が使えない場合のみ web_fetch にフォールバック
