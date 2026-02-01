# raphaelsimon.fr - Architecture

Personal blog with automated content pipeline from Obsidian notes.

## Overview

```
┌──────────────────────────────────────────────────────────────┐
│                      CONTENT CREATION                         │
│                                                               │
│   Phone/Tablet/Laptop → Obsidian → Dropbox → Pi → Analysis   │
│                                        ↓                      │
│                                   Telegram alert              │
│                                   "Topic X is ready"          │
└──────────────────────────────────────────────────────────────┘
                                        ↓
┌──────────────────────────────────────────────────────────────┐
│                      BLOG PUBLISHING                          │
│                                                               │
│   Write post → Push to GitHub → Cloudflare Pages → Live      │
└──────────────────────────────────────────────────────────────┘
```

---

## 1. Static Site Hosting: Cloudflare Pages

### Why Cloudflare over Netlify

| Aspect | Cloudflare Pages | Netlify |
|--------|------------------|---------|
| **Edge locations** | 300+ data centers | AWS edge nodes (fewer) |
| **Free tier bandwidth** | Unlimited | 100 GB/month |
| **Protocol** | HTTP/3 | HTTP/2 only |
| **Global latency** | Superior (especially Asia/Africa/ME) | Good for US/EU |
| **Serverless** | Workers (V8 isolates, ~0ms cold start) | Edge Functions (Deno) |
| **Storage** | R2, KV, D1 integrated | External services needed |
| **Build minutes** | 500/month free | 300/month free |

**Technical impact:**

1. **Performance**: Anycast network = fast globally. Matters for French expat readers worldwide.
2. **Cost**: Truly free for static sites. No bandwidth overages. R2 has no egress fees.
3. **Ecosystem**: Workers + KV + D1 available if you need serverless later.
4. **DX**: CLI-centric (`wrangler`). Fits a technical workflow.
5. **Future-proof**: HTTP/3, Brotli, image optimization, Early Hints.

### Deployment

```bash
# Install wrangler CLI
npm install -g wrangler

# Authenticate
wrangler login

# Deploy (from repo root, after building)
wrangler pages deploy ./dist --project-name=raphaelsimon-fr
```

Or connect GitHub repo in Cloudflare dashboard for automatic deploys.

---

## 2. Blog Post Detection System

### The Problem

Scattered thoughts in Obsidian across devices. Reviewing them to find blog-ready topics is tedious. Posts don't get written.

### The Solution

**Dropbox sync + Raspberry Pi analyzer**

```
┌─────────────────────────────────────────────────────────────────┐
│                         YOUR DEVICES                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                       │
│  │ Laptop   │  │  iPhone  │  │   iPad   │                       │
│  │ Obsidian │  │ Obsidian │  │ Obsidian │                       │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘                       │
│       └─────────────┴─────────────┘                              │
│                     │                                            │
│              Dropbox Sync (native in Obsidian)                   │
└─────────────────────┬───────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                        DROPBOX CLOUD                             │
└─────────────────────┬───────────────────────────────────────────┘
                      │ rclone sync (every 15 min)
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                    RASPBERRY PI 4                                │
│                    (USB SSD, always-on)                          │
│                                                                  │
│  ~/vault/           ← synced Obsidian vault                     │
│  ~/analyzer/        ← analysis scripts + cron                   │
│                                                                  │
│  Daily at 09:00:                                                │
│  1. Parse vault, cluster notes by tags/links                    │
│  2. Send clusters to Claude API                                 │
│  3. If mature topics found → Telegram notification              │
└─────────────────────────────────────────────────────────────────┘
```

**Why this approach:**

- **Dropbox over Obsidian Sync**: Native mobile support, free, exposes files to rclone. Obsidian Sync is E2E encrypted with no API.
- **Pi over VPS**: Already owned, already on, already running homepage.
- **USB SSD over SD card**: Frequent writes would wear SD card. SSD handles it fine.

### What Makes a Topic "Mature"?

The analyzer looks for:

1. **Volume**: 3+ notes on the same topic (linked or tagged)
2. **Depth**: Combined word count > 1000 words
3. **Structure**: Arguments, examples, conclusions present
4. **Recency**: Recent edits indicate active thinking
5. **Coherence**: Notes connect logically (Claude assesses this)

### Setup

See **[PI_SETUP.md](./PI_SETUP.md)** for complete setup instructions:
- SSD migration from SD card
- Power considerations
- Dropbox + rclone configuration
- Analyzer deployment
- Telegram bot setup

---

## 3. Static Site Generator

For the blog itself:

| | Hugo | Astro |
|--|------|-------|
| Build speed | Fastest (~1ms/page) | Fast (~10ms/page) |
| Language | Go templates | JS/TS, any framework |
| Learning curve | Steeper | Gentler |
| Extensibility | Limited | Full JS ecosystem |

**Hugo** if you want pure markdown-to-HTML. **Astro** if you want components or interactivity.

Both deploy trivially to Cloudflare Pages.

---

## 4. Cost Summary

| Component | Monthly Cost |
|-----------|--------------|
| Cloudflare Pages | $0 |
| Dropbox (2GB free tier) | $0 |
| Raspberry Pi electricity (~5W) | ~$0.50 |
| Anthropic API (1 call/day, Haiku) | ~$1-3 |
| **Total** | **~$1.50-3.50** |

Compared to Obsidian Sync alone ($8/month), this is cheaper AND adds automation.

---

## 5. Security Notes

- Dropbox vault folder should not contain sensitive credentials
- Anthropic API key stored in `~/.bashrc` or `.env` on Pi (not in repo)
- Pi should have SSH key auth, no password login
- Consider firewall rules if Pi is exposed to internet

---

## 6. Files in This Repo

```
raphaelsimon.fr/
├── ARCHITECTURE.md          # This file
├── PI_SETUP.md              # Raspberry Pi setup guide
├── tools/
│   ├── analyze_vault.py     # Obsidian analyzer script
│   └── requirements.txt     # Python dependencies
└── .github/
    └── workflows/
        └── analyze-vault.yml  # (Alternative: GitHub Actions approach)
```
