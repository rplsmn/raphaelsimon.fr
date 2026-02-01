# raphaelsimon.fr - Architecture

Personal blog with automated content pipeline from Obsidian notes.

## 1. Static Site Hosting: Cloudflare Pages

### Why Cloudflare over Netlify

| Aspect | Cloudflare Pages | Netlify |
|--------|------------------|---------|
| **Edge locations** | 300+ data centers | AWS edge nodes (fewer) |
| **Free tier bandwidth** | Unlimited | 100 GB/month |
| **Protocol** | HTTP/3 | HTTP/2 only |
| **Global latency** | Superior (especially Asia/Africa/ME) | Good for US/EU |
| **Serverless** | Workers (V8 isolates, cold start ~0ms) | Edge Functions (Deno) |
| **Storage** | R2, KV, D1 (SQLite) integrated | External services needed |
| **Build minutes** | 500/month free | 300/month free |

**Technical impact of choosing Cloudflare:**

1. **Performance**: Cloudflare's anycast network means your blog loads fast everywhere. For a personal blog with potential global readership (French expat communities, tech readers worldwide), this matters.

2. **Cost**: Truly free for static sites. No bandwidth overages. R2 storage for assets has no egress fees.

3. **Ecosystem**: If you later need a contact form, analytics, or serverless functions, Cloudflare Workers + KV + D1 are all integrated. No vendor lock-in to external services.

4. **Developer experience**: More CLI-centric than Netlify's GUI approach. Deploy with `wrangler` or git push. Fits a technical user's workflow.

5. **Future-proof**: HTTP/3, Brotli compression, automatic image optimization (via Polish), and Early Hints are available or easy to enable.

### Deployment Setup

```bash
# Install wrangler CLI
npm install -g wrangler

# Authenticate
wrangler login

# Deploy (from repo root, after building)
wrangler pages deploy ./dist --project-name=raphaelsimon-fr
```

Or connect GitHub repo in Cloudflare dashboard for automatic deploys on push.

---

## 2. Blog Post Detection: From Obsidian Chaos to Published Posts

### The Problem

You have scattered thoughts in Obsidian, tagged when disciplined, across all devices via Obsidian Sync. Reviewing them to find "blog-ready" topics is tedious, so posts don't get written.

### Challenging Your Current Setup

**Obsidian Sync ($8/month) is the bottleneck.** It's end-to-end encrypted with no API. You cannot programmatically access your vault from the cloud. This forces any automation to run locally on one device (which defeats the multi-device benefit).

**Recommendation: Replace Obsidian Sync with Git-based sync.**

| Obsidian Sync | Git Sync (via Obsidian Git plugin) |
|---------------|-----------------------------------|
| $8/month | Free |
| No version history UI | Full git history, blame, diff |
| No API access | Full API access via GitHub/GitLab |
| Works on mobile | Works on mobile (with caveats) |
| E2E encrypted | Private repo (encrypted at rest on GitHub) |

The [Obsidian Git plugin](https://github.com/denolehov/obsidian-git) is mature (1.5M+ downloads, actively maintained). It auto-commits and syncs on a schedule. Mobile support exists via the Obsidian Git plugin on iOS/Android (requires git credentials).

**If you must keep Obsidian Sync**: Run the analyzer as a local agent on your primary machine. Less elegant but works.

---

## 3. The Blog Maturity Analyzer

### Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         YOUR DEVICES                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                       │
│  │ MacBook  │  │  iPhone  │  │   iPad   │                       │
│  │ Obsidian │  │ Obsidian │  │ Obsidian │                       │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘                       │
│       │             │             │                              │
│       └─────────────┴─────────────┘                              │
│                     │                                            │
│            Obsidian Git Plugin                                   │
│            (auto-commit every 5 min)                             │
└─────────────────────┬───────────────────────────────────────────┘
                      │ git push
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                    GITHUB (Private Repo)                         │
│                    your-obsidian-vault                           │
│                                                                  │
│  on: schedule (daily) or push ──► GitHub Actions Workflow        │
└─────────────────────────────────┬───────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────┐
│                    ANALYZER WORKFLOW                             │
│                                                                  │
│  1. Checkout vault                                               │
│  2. Parse markdown files in /thoughts or tagged #idea           │
│  3. Build topic clusters (by tags, links, keywords)             │
│  4. Send to Claude API for maturity assessment                  │
│  5. If mature topics found → Send notification                  │
│                                                                  │
│  Estimated cost: ~$0.10-0.50/day with Claude Haiku              │
└─────────────────────────────────┬───────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────┐
│                    NOTIFICATION                                  │
│                                                                  │
│  Options:                                                        │
│  - Email (via SendGrid/Resend, free tier)                       │
│  - Telegram bot (free)                                          │
│  - Discord webhook (free)                                       │
│  - Push notification (via ntfy.sh, free)                        │
│                                                                  │
│  "3 topics ready for blog posts:                                │
│   1. Your thoughts on AI agents (7 notes, 2.3k words)           │
│   2. Remote work in 2025 (4 notes, 1.8k words)                  │
│   3. Learning Rust (5 notes, strong progression arc)"           │
└─────────────────────────────────────────────────────────────────┘
```

### What Makes a Topic "Mature"?

The analyzer looks for signals:

1. **Volume**: Multiple notes on the same topic (linked or tagged)
2. **Depth**: Total word count across related notes
3. **Structure**: Presence of arguments, examples, conclusions
4. **Recency**: Recent activity indicates active thinking
5. **Coherence**: Notes that connect logically (via Claude analysis)
6. **Completeness**: A narrative arc or clear thesis emerging

### The Prompt (for Claude API)

```
You are analyzing a personal knowledge base to identify topics mature
enough for blog posts. A topic is "mature" when:

- There are 3+ notes on the topic (linked, tagged, or semantically related)
- Combined content exceeds 1000 words
- There's a clear perspective or argument emerging
- The writing shows depth (examples, nuance, not just bullet points)
- Recent edits suggest active development

For each mature topic found, provide:
1. Topic title
2. Related notes (filenames)
3. Estimated word count
4. Why it's ready (1 sentence)
5. Suggested blog post angle

Be selective. Only surface truly ready topics, not half-formed ideas.
```

### Implementation: GitHub Actions Workflow

```yaml
# .github/workflows/analyze-vault.yml
name: Analyze Obsidian Vault

on:
  schedule:
    - cron: '0 8 * * *'  # Daily at 8 AM UTC
  workflow_dispatch:      # Manual trigger

jobs:
  analyze:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          repository: ${{ secrets.VAULT_REPO }}
          token: ${{ secrets.VAULT_PAT }}
          path: vault

      - uses: actions/setup-python@v5
        with:
          python-version: '3.12'

      - name: Install dependencies
        run: pip install anthropic pyyaml

      - name: Run analyzer
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
          TELEGRAM_BOT_TOKEN: ${{ secrets.TELEGRAM_BOT_TOKEN }}
          TELEGRAM_CHAT_ID: ${{ secrets.TELEGRAM_CHAT_ID }}
        run: python analyze.py

      - name: Send notification
        if: env.MATURE_TOPICS != ''
        run: |
          curl -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
            -d "chat_id=$TELEGRAM_CHAT_ID" \
            -d "text=$MATURE_TOPICS" \
            -d "parse_mode=Markdown"
```

### Cost Breakdown

| Component | Cost |
|-----------|------|
| GitHub Actions | Free (2000 min/month for private repos) |
| Anthropic API (Claude Haiku) | ~$0.10-0.50/day (depends on vault size) |
| Telegram notifications | Free |
| **Total** | **~$3-15/month** |

Alternatively, use a VPS ($5/month DigitalOcean droplet) with a cron job if you prefer self-hosting.

---

## 4. Alternative: Keep Obsidian Sync (Local Agent)

If you don't want to switch to git sync, run the analyzer locally:

```python
#!/usr/bin/env python3
"""Local Obsidian analyzer - runs on your primary device."""

import os
import anthropic
import requests
from pathlib import Path
from datetime import datetime

VAULT_PATH = Path.home() / "Documents" / "Obsidian" / "MyVault"
THOUGHTS_FOLDER = "thoughts"  # or wherever your ideas live

def main():
    # Collect notes
    notes = []
    for md_file in (VAULT_PATH / THOUGHTS_FOLDER).rglob("*.md"):
        notes.append({
            "name": md_file.name,
            "content": md_file.read_text(),
            "modified": datetime.fromtimestamp(md_file.stat().st_mtime)
        })

    # Analyze with Claude
    client = anthropic.Anthropic()
    # ... analysis logic ...

    # Send notification if topics found
    # ... telegram/email notification ...

if __name__ == "__main__":
    main()
```

Run via cron (Linux/Mac) or Task Scheduler (Windows).

**Downside**: Only runs when that device is on. Misses the "always watching" benefit of cloud.

---

## 5. Static Site Generator

For the blog itself, recommend **Hugo** or **Astro**:

| | Hugo | Astro |
|--|------|-------|
| Build speed | Fastest (~1ms/page) | Fast (~10ms/page) |
| Language | Go templates | JS/TS, any framework |
| Learning curve | Steeper | Gentler |
| Extensibility | Limited | Full JS ecosystem |

Hugo is ideal if you want pure static markdown-to-HTML. Astro if you want components or interactivity.

Both deploy trivially to Cloudflare Pages.

---

## 6. Summary & Next Steps

1. **Set up Cloudflare Pages** - Connect this repo, configure build command
2. **Migrate to git sync** - Install Obsidian Git plugin, create private vault repo
3. **Deploy analyzer** - GitHub Actions workflow with Claude API
4. **Set up notifications** - Telegram bot (easiest) or email

The goal: You write thoughts in Obsidian. The system tells you when they're ready to become posts. You just have to write the final article.

---

## Appendix: Security Notes

- Vault repo should be **private**
- Use GitHub fine-grained PAT with minimal permissions
- Anthropic API key stored as GitHub secret
- Consider excluding sensitive notes via `.gitignore` in vault
