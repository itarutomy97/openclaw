# GitHub Issue Draft: LINE Channel Restart Loop Bug

## Title
LINE webhook channel triggers restart loop due to immediately-resolving monitorLineProvider

## Description

### Problem
The LINE channel's `gateway.startAccount` function calls `monitorLineProvider()` which registers a webhook route and resolves immediately. The gateway's restart mechanism interprets resolved promises as "channel stopped" and triggers auto-restart in a loop.

### Root Cause
In `extensions/line/src/channel.ts`, the `startAccount` method:
```typescript
return getLineRuntime().channel.line.monitorLineProvider({
  channelAccessToken: token,
  channelSecret: secret,
  accountId: account.accountId,
  config: ctx.cfg,
  runtime: ctx.runtime,
  abortSignal: ctx.abortSignal,
  webhookPath: account.config.webhookPath,
});
```

Unlike WebSocket-based channels (Telegram, Discord), the LINE webhook provider returns immediately after registering the HTTP route. The gateway wrapper expects the promise to stay pending while the channel is active.

### Suggested Fix
Add abort signal waiting in `startAccount`:

```typescript
const monitor = await getLineRuntime().channel.line.monitorLineProvider({
  channelAccessToken: token,
  channelSecret: secret,
  accountId: account.accountId,
  config: ctx.cfg,
  runtime: ctx.runtime,
  abortSignal: ctx.abortSignal,
  webhookPath: account.config.webhookPath,
});

// Keep the channel alive until abort signal fires (webhook provider fix)
await new Promise<void>((resolve) => {
  if (ctx.abortSignal?.aborted) { resolve(); return; }
  ctx.abortSignal?.addEventListener("abort", () => resolve(), { once: true });
});

return monitor;
```

### Environment
- OpenClaw version: 2026.2.17
- Node.js: v24.13.1
- OS: Ubuntu 24.04 LTS

### Impact
Users cannot use LINE channel with webhook mode without manually patching the npm package, which is lost on every `npm update`.

---

**Labels**: bug, channel/line, priority/high
