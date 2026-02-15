# Research Report: LLM-Assisted Content Pipeline Automation Patterns

**Date**: 2026-02-15

---

## Table of Contents

1. [Claude Code in Automated/Cron Workflows](#1-claude-code-in-automatedcron-workflows)
2. [Feeding Local Files to LLM Tools Without Committing](#2-feeding-local-files-to-llm-tools-without-committing)
3. [Claude Code MCP Filesystem Server](#3-claude-code-mcp-filesystem-server)
4. [Raspberry Pi as Always-On Automation Hub](#4-raspberry-pi-as-always-on-automation-hub)
5. [GitHub Actions for Periodic Content Processing](#5-github-actions-for-periodic-content-processing)
6. [Tailscale-Based Workflows](#6-tailscale-based-workflows)
7. [Note Maturity Assessment Tools](#7-note-maturity-assessment-tools)
8. [Mobile Terminal Workflows](#8-mobile-terminal-workflows)
9. [Architecture Recommendations](#9-architecture-recommendations)

---

## 1. Claude Code in Automated/Cron Workflows

### Core Mechanism: `--print` (`-p`) Flag

The `-p` flag runs Claude Code non-interactively, executing a single query and outputting results directly to stdout. This is the foundation for all automation.

```bash
# Basic non-interactive usage
claude -p "Summarize this project" --output-format json

# Pipe input to Claude
cat notes.md | claude -p "Assess if this note has enough content for an article"

# Structured output with JSON schema
claude -p "Extract metadata from this file" \
  --output-format json \
  --json-schema '{"type":"object","properties":{"title":{"type":"string"},"maturity":{"type":"number"}}}'

# Continue conversations across invocations
session_id=$(claude -p "Start reviewing notes" --output-format json | jq -r '.session_id')
claude -p "Continue with the next batch" --resume "$session_id"
```

### `--dangerously-skip-permissions` for Full Automation

This flag bypasses all interactive permission prompts, enabling true unattended execution.

**Safety requirements:**
- Run in a locked-down container or VM, preferably sandboxed
- Configure an `AllowedTools` whitelist in config to restrict Claude to safe actions
- Use only for non-critical, well-scoped tasks

**Safer alternative:** Use `--allowedTools` to whitelist specific tools:
```bash
claude -p "Review staged changes and create a commit" \
  --allowedTools "Bash(git diff *),Bash(git log *),Bash(git status *),Bash(git commit *)"
```

### Cron Integration Pattern

```bash
# Example crontab entry: run daily at 6 AM
0 6 * * * /home/user/scripts/auto-content-review.sh >> /home/user/logs/content-review.log 2>&1
```

Example automation script:
```bash
#!/bin/bash
export ANTHROPIC_API_KEY="sk-..."
cd /path/to/content-repo

# Assess all draft notes
for note in drafts/*.md; do
  result=$(cat "$note" | claude -p \
    "Assess this note's readiness for publication. Return JSON with fields: title, maturity_score (1-10), missing_elements, recommendation." \
    --output-format json \
    --json-schema '{"type":"object","properties":{"title":{"type":"string"},"maturity_score":{"type":"number"},"missing_elements":{"type":"array","items":{"type":"string"}},"recommendation":{"type":"string"}},"required":["title","maturity_score","missing_elements","recommendation"]}')
  echo "$result" >> assessment-results.json
done
```

### Dedicated Tools

| Tool | Description | URL |
|------|-------------|-----|
| **claude-code-scheduler** | Plugin for Claude Code. Natural language scheduling ("every weekday at 9am"). Uses native OS schedulers (launchd/crontab/Task Scheduler). Supports autonomous mode with git worktree isolation. | https://github.com/jshchnz/claude-code-scheduler |
| **runCLAUDErun** | Native macOS app for scheduling Claude Code tasks. GUI-based, no cron syntax needed. | https://runclauderun.com |
| **claudecron** | MCP server with cron-style scheduling of AI/shell tasks, designed for use with Claude Code. | https://github.com/phildougherty/claudecron |
| **claude-mcp-scheduler** | Uses Claude API to prompt remote agents on a cron interval, uses local MCPs for tool calls. | https://github.com/tonybentley/claude-mcp-scheduler |

### Claude Code SDK (Programmatic Access)

Released June 2025 for Python and TypeScript. Provides full programmatic control:

```python
# Python SDK example (async-first)
from claude_code_sdk import ClaudeCode

async def assess_note(note_path: str):
    agent = ClaudeCode()
    result = await agent.run(
        prompt=f"Read {note_path} and assess its maturity for publication",
        allowed_tools=["Read"],
        output_format="json"
    )
    return result
```

**Sources:**
- https://code.claude.com/docs/en/headless
- https://github.com/jshchnz/claude-code-scheduler
- https://blog.promptlayer.com/claude-dangerously-skip-permissions/
- https://www.blle.co/blog/automated-claude-code-workers

---

## 2. Feeding Local Files to LLM Tools Without Committing

### Method 1: `--add-dir` Flag (Recommended)

Added in Claude Code v1.0.18. Extends your workspace beyond the current repo:

```bash
# At launch: add external notes directory
claude --add-dir ~/Documents/notes --add-dir ~/Google\ Drive/drafts

# During interactive session
/add-dir ~/Documents/notes
```

As of v2.1.20, Claude Code loads CLAUDE.md files from `--add-dir` directories when `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1` is set.

### Method 2: Symlinks into the Repo

Create symlinks from within the repo pointing to external directories:

```bash
# Create a symlink to your notes directory
ln -s ~/Documents/notes /path/to/repo/external-notes

# Add to .gitignore so it's never committed
echo "external-notes" >> .gitignore
```

**Caveats:**
- Claude Code follows symlinks transparently for read/edit operations
- `.claude/rules/` directory fully supports symlinks
- On some platforms, symlinks pointing outside allowed root directories may be skipped
- There was a historical bug (issue #764) with symlink resolution, mostly resolved

### Method 3: MCP Filesystem Server

Run a separate MCP server that gives Claude access to specific directories:

```json
// .claude/mcp.json (project-level MCP config)
{
  "mcpServers": {
    "notes-filesystem": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "/home/user/Documents/notes",
        "/home/user/Google Drive/drafts"
      ]
    }
  }
}
```

### Method 4: Bind Mounts (Docker/Container Workflows)

When running Claude Code in a container:

```bash
docker run -v ~/Documents/notes:/workspace/notes \
           -v ~/Google\ Drive/drafts:/workspace/drafts \
           claude-code-image
```

### Method 5: Cloud Storage MCP Servers

For Google Drive specifically, multiple MCP servers exist:

| Server | Features | URL |
|--------|----------|-----|
| **googleDriveMCP** | Read/list Google Drive files and folders | https://github.com/michaelpine25/googleDriveMCP |
| **google-docs-mcp** | Full access to Google Docs, Sheets & Drive with direct editing | https://github.com/a-bonus/google-docs-mcp |
| **hardened-google-workspace-mcp** | Security-hardened version covering Drive, Docs, Sheets, Slides, Gmail | https://github.com/c0webster/hardened-google-workspace-mcp |
| **google-workspace-mcp** | Full Google Workspace integration | https://github.com/crazybass81/google-workspace-mcp |

**Setup requires:** Google Cloud project with OAuth 2.0 credentials, Drive API enabled.

**Security warning:** Understand prompt injection risks before connecting Claude to email/Drive. The "lethal trifecta" (read access + write access + external content) creates attack surface.

**Sources:**
- https://claudelog.com/faqs/--add-dir/
- https://github.com/modelcontextprotocol/servers/tree/main/src/filesystem
- https://wow.pjh.is/journal/claude-code-google-workspace-mcp
- https://github.com/michaelpine25/googleDriveMCP

---

## 3. Claude Code MCP Filesystem Server - Detailed Analysis

### Can It Access Files Outside the Current Repo? Yes.

The MCP Filesystem Server is designed exactly for this purpose. You specify allowed directories via command-line arguments:

```bash
npx -y @modelcontextprotocol/server-filesystem /path/to/dir1 /path/to/dir2
```

### Directory Access Control System

1. **Command-line arguments**: Specify allowed directories at startup
2. **MCP Roots (recommended)**: Clients supporting Roots can dynamically update allowed directories at runtime via `roots/list_changed` notifications
3. **Hybrid**: Roots completely replace command-line directories when provided

### Available Tools

The server provides: `read_text_file`, `read_media_file`, `read_multiple_files`, `write_file`, `edit_file`, `create_directory`, `list_directory`, `list_directory_with_sizes`, `move_file`, `search_files`, `directory_tree`, `get_file_info`.

### Configuration for Content Pipeline

```json
// ~/.claude/mcp.json (user-level, applies to all projects)
{
  "mcpServers": {
    "content-notes": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "/home/user/Documents/raw-notes",
        "/home/user/Documents/drafts",
        "/home/user/Google Drive/My Drive/Notes"
      ]
    }
  }
}
```

### Security Note

A path validation bypass vulnerability was reported to Anthropic in June 2025 and subsequently fixed when they rewrote the server to support the Roots feature. Use the latest version.

**Sources:**
- https://github.com/modelcontextprotocol/servers/tree/main/src/filesystem
- https://thenewstack.io/give-claude-ai-full-access-to-your-local-filesystem-with-mcp/
- https://embracethered.com/blog/posts/2025/anthropic-filesystem-mcp-server-bypass/

---

## 4. Raspberry Pi as Always-On Automation Hub

### Why a Raspberry Pi?

- Ultra-low power consumption (~5-15W depending on model)
- Runs 24/7 reliably when connected via Ethernet
- Any model with Ethernet works for cron-based automation
- Pi 5 (8GB) can even run local LLMs up to 7B parameters via Ollama

### Recommended Architecture for Content Pipeline

```
┌─────────────────────────────────────────────────────┐
│  Raspberry Pi 5 (8GB)                               │
│                                                      │
│  ┌──────────────┐  ┌──────────────┐                 │
│  │  Tailscale    │  │  Cron Jobs   │                 │
│  │  (VPN mesh)   │  │  (Scheduler) │                 │
│  └──────┬───────┘  └──────┬───────┘                 │
│         │                  │                          │
│  ┌──────┴──────────────────┴───────┐                 │
│  │  Claude Code CLI (-p mode)      │                 │
│  │  + Anthropic API Key            │                 │
│  └──────┬──────────────────────────┘                 │
│         │                                            │
│  ┌──────┴──────────────────────────┐                 │
│  │  MCP Servers:                   │                 │
│  │  - Filesystem (local notes)     │                 │
│  │  - Google Drive (cloud notes)   │                 │
│  └──────┬──────────────────────────┘                 │
│         │                                            │
│  ┌──────┴──────────────────────────┐                 │
│  │  Git repo (blog source)         │                 │
│  │  → Push to GitHub for Pages     │                 │
│  └─────────────────────────────────┘                 │
└─────────────────────────────────────────────────────┘
```

### Setup Steps

1. **Install Raspberry Pi OS Lite** (headless, no desktop)
2. **Install Tailscale**: `curl -fsSL https://tailscale.com/install.sh | sh` - disable key expiry for always-on server
3. **Install Node.js and Claude Code**: Claude Code runs as a Node.js CLI
4. **Configure cron jobs** for content pipeline tasks
5. **Mount or sync notes**: Use rclone for Google Drive, or rsync for local devices over Tailscale

### Running Local LLMs (Alternative to API)

For offline/cost-free assessment:
- **Ollama** with quantized models (Qwen 2.5 7B, Llama 3.2 3B) on Pi 5 with 8GB RAM
- 15+ tokens/second with optimized 4-bit quantization
- Suitable for note classification and simple assessment, not full article generation

### Power and Reliability

- Use a UPS HAT for power resilience
- Configure automatic restart on boot: `systemctl enable tailscaled`
- Monitor with a simple health-check cron that pings a heartbeat URL

**Sources:**
- https://learn.adafruit.com/local-llms-on-raspberry-pi/overview
- https://www.xda-developers.com/automated-half-digital-life-raspberry-pi-cron-jobs/
- https://medium.com/@shreysid2352/from-pi-to-powerhouse-the-ultimate-diy-cloud-server-with-tailscale-sharing-a47e1e7816d8

---

## 5. GitHub Actions for Periodic Content Processing

### Anthropic's Official Claude Code Action

```yaml
# .github/workflows/content-pipeline.yml
name: Content Pipeline
on:
  schedule:
    - cron: '0 6 * * *'  # Daily at 6 AM UTC
  workflow_dispatch:       # Manual trigger

jobs:
  assess-notes:
    runs-on: ubuntu-latest
    permissions:
      contents: write
      pull-requests: write
    steps:
      - uses: actions/checkout@v4

      - name: Assess draft notes
        uses: anthropics/claude-code-action@v1
        with:
          prompt: |
            Review all files in the drafts/ directory.
            For each note, assess its maturity on a 1-10 scale.
            Create a summary report at reports/daily-assessment.md.
            If any note scores 8+, create a PR to move it to ready/.
          anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
          allowed_tools: "Read,Write,Bash(git *)"
```

### Key Features

- **Free tier**: 2,000 minutes/month on GitHub's free plan
- **Scheduled runs**: Full cron syntax support
- **PR-based workflow**: Claude can create PRs with processed content
- **Multiple auth methods**: Anthropic direct API, Amazon Bedrock, Google Vertex AI

### Alternative: Direct CLI in GitHub Actions

```yaml
- name: Install Claude Code
  run: npm install -g @anthropic-ai/claude-code

- name: Run content assessment
  env:
    ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
  run: |
    for note in drafts/*.md; do
      claude -p "Assess this note for publication readiness: $(cat $note)" \
        --output-format json >> assessments.json
    done
```

### Practical Patterns

1. **Daily content review**: Assess all drafts, generate maturity reports
2. **Weekly digest**: Summarize notes added in the past week
3. **Auto-PR for mature notes**: When a note reaches threshold, create a PR moving it to the publication queue
4. **Dependency on external content**: Sync notes from Google Drive via rclone before processing

**Sources:**
- https://code.claude.com/docs/en/github-actions
- https://github.com/anthropics/claude-code-action
- https://simonwillison.net/2025/Jul/1/claude-code-github-actions/
- https://medium.com/@fra.bernhardt/automate-your-documentation-with-claude-code-github-actions-a-step-by-step-guide-2be2d315ed45

---

## 6. Tailscale-Based Workflows

### Why Tailscale for Content Pipelines?

- **Zero-config VPN mesh**: All devices see each other by hostname
- **Works through NATs/firewalls**: No port forwarding needed
- **Free for personal use**: Up to 100 devices
- **Perfect for Pi <-> Desktop <-> Mobile connectivity**

### Architecture Pattern

```
iPhone (Termius/Blink)
    ↕ Tailscale
Raspberry Pi (always-on)
    ↕ Tailscale
Desktop/Laptop (primary dev)
    ↕ Tailscale
GitHub (CI/CD)
```

### Key Integrations

1. **GitHub Actions + Tailscale**: Use `tailscale/github-action@v4` to connect GitHub runners to your tailnet, accessing Pi-hosted services during CI.
2. **Tailscale Services**: Assign virtual IPs to logical resources, usable in automated workflows.
3. **Tailscale Funnel**: Expose services publicly (e.g., Quarto preview) without port forwarding.
4. **SSH via Tailscale**: `ssh pi@raspberrypi` from anywhere - including from mobile.

### Content Pipeline with Tailscale

```bash
# On iPhone via Termius/Blink, SSH to Pi:
ssh pi@rpi.tail1234.ts.net

# On Pi, sync notes from desktop:
rsync -avz desktop.tail1234.ts.net:~/Documents/notes/ ~/content-pipeline/incoming/

# Or mount desktop directory via sshfs:
sshfs desktop.tail1234.ts.net:~/Documents/notes ~/content-pipeline/incoming/
```

### Disable Key Expiry

For always-on Pi servers, disable key expiry in the Tailscale admin console to prevent the Pi from falling off the tailnet.

**Sources:**
- https://tailscale.com/kb/1430/automations
- https://tailscale.com/blog/github-action-v4
- https://tailscale.com/blog/services-beta

---

## 7. Note Maturity Assessment Tools and Prompts

### No Off-the-Shelf "Note Maturity Assessment" Tool Exists

This is a gap in the ecosystem. The closest tools are Zettelkasten assistants that evaluate note structure, but nothing specifically assesses publication readiness. **This is an opportunity to build a custom solution.**

### Recommended Approach: Custom Assessment Prompt

Here is a prompt template designed for assessing note maturity:

```
You are a content editor assessing whether raw notes have enough material
for a publishable blog article. Evaluate the following note and return a
JSON assessment.

## Scoring Criteria (each 1-10):

1. **Core Thesis** (weight: 3x): Is there a clear central argument or insight?
2. **Supporting Evidence** (weight: 2x): Are there enough examples, data, or
   references to support the thesis?
3. **Structure Potential** (weight: 2x): Can the notes be organized into a
   coherent article structure (intro, body, conclusion)?
4. **Unique Value** (weight: 2x): Does the content offer a perspective not
   easily found elsewhere?
5. **Completeness** (weight: 1x): Are there obvious gaps that would require
   significant additional research?

## Output Format:
{
  "title_suggestion": "string",
  "overall_score": number (weighted average, 1-10),
  "scores": {
    "core_thesis": number,
    "supporting_evidence": number,
    "structure_potential": number,
    "unique_value": number,
    "completeness": number
  },
  "recommendation": "ready" | "needs_work" | "seed_only",
  "missing_elements": ["string"],
  "suggested_outline": ["string"],
  "estimated_word_count": number,
  "tags": ["string"]
}

## The Note:
---
{note_content}
---
```

### Using This in Automation

```bash
#!/bin/bash
# assess-note.sh - Run against a single note
NOTE_CONTENT=$(cat "$1")
PROMPT=$(cat assessment-prompt.txt)
PROMPT="${PROMPT/\{note_content\}/$NOTE_CONTENT}"

claude -p "$PROMPT" \
  --output-format json \
  --json-schema '{"type":"object","properties":{"title_suggestion":{"type":"string"},"overall_score":{"type":"number"},"recommendation":{"type":"string","enum":["ready","needs_work","seed_only"]},"missing_elements":{"type":"array","items":{"type":"string"}},"suggested_outline":{"type":"array","items":{"type":"string"}},"estimated_word_count":{"type":"number"},"tags":{"type":"array","items":{"type":"string"}}},"required":["title_suggestion","overall_score","recommendation"]}'
```

### Related Tools

| Tool | Description | URL |
|------|-------------|-----|
| **Zettel Assistant** (ChatGPT GPT) | Evaluates Zettelkasten notes for structure and thematic linkage | https://www.yeschat.ai/gpts-9t55kJHDeoj-Zettel-Assistant |
| **AI Zettelkasten Lite** | Claude Code + Pinecone for knowledge management with CEQRC workflow | https://github.com/logicalicy/ai-zettelkasten-lite |
| **Obsidian Copilot Plugin** | In-editor AI prompts for note enhancement | https://obsidian.md/plugins?search=ai |
| **G-Eval Framework** | LLM-as-a-Judge evaluation with custom rubrics | https://www.confident-ai.com/blog/llm-evaluation-metrics-everything-you-need-for-llm-evaluation |

**Sources:**
- https://www.yeschat.ai/gpts-9t55kJHDeoj-Zettel-Assistant
- https://github.com/logicalicy/ai-zettelkasten-lite
- https://www.evidentlyai.com/llm-guide/llm-as-a-judge

---

## 8. Mobile Terminal Workflows

### Top Mobile Terminal Apps for Content Pipeline Work

| App | Platform | Key Feature | Price | URL |
|-----|----------|-------------|-------|-----|
| **Blink Shell** | iOS | Mosh support (survives disconnects), VS Code integration | Subscription (~$16/yr) | https://blink.sh |
| **Moshi** | iOS | Native mosh, push notifications for agent events, voice input for AI agents | Subscription | https://getmoshi.app |
| **Termius** | iOS/Android | Cross-platform sync, SFTP, multi-window | Free tier + subscription | https://termius.com |
| **a-Shell** | iOS | Local terminal with Python, Lua, C, vim, grep, awk. Fully offline. Free. | Free | https://apps.apple.com/us/app/a-shell/id1473805438 |

### Recommended Mobile Workflow

1. **Blink Shell or Moshi** on iPhone/iPad for SSH into Raspberry Pi via Tailscale
2. **Mosh protocol** for resilient connections (survives network switches, sleep/wake)
3. **tmux on the Pi** for persistent sessions
4. **Claude Code on Pi** via SSH - run `claude` interactively or `claude -p` for quick tasks

### a-Shell for Offline Local Work

a-Shell runs a full Unix environment locally on iOS:
- Python, Lua, C, C++ available
- vim/ed for editing
- grep, awk, sed for text processing
- Shortcuts integration for automation
- **Cannot run Claude Code directly** (no Node.js), but useful for local note preprocessing

### Claude Code iOS App

In late 2025, Anthropic extended Claude Code to their iOS app, providing a native mobile-first development experience without needing SSH at all.

**Sources:**
- https://blink.sh
- https://getmoshi.app/articles/best-ios-terminal-app-coding-agent
- https://termius.com
- https://holzschu.github.io/a-Shell_iOS/
- https://sealos.io/blog/claude-code-on-phone

---

## 9. Architecture Recommendations

### Recommended Stack for Your Use Case

Given the raphaelsimon.fr Quarto blog with a content pipeline goal:

#### Tier 1: Minimal Setup (Start Here)

```
iPhone (notes in Apple Notes / Google Docs)
    → Manual export to ~/Documents/notes/
        → Claude Code on laptop with --add-dir ~/Documents/notes
            → Quarto blog repo → GitHub Pages
```

**Tools needed:** Claude Code CLI, `--add-dir` flag, a simple shell script.

#### Tier 2: Semi-Automated

```
Notes (anywhere)
    → Sync to GitHub repo (drafts/ folder, gitignored or private)
        → GitHub Actions (scheduled) runs Claude assessment
            → Creates PRs for mature notes
                → Manual review → Merge → GitHub Pages deploys
```

**Tools needed:** GitHub Actions + `anthropics/claude-code-action`, assessment prompt.

#### Tier 3: Full Automation with Pi Hub

```
iPhone (Blink/Moshi via Tailscale)
    ↕
Raspberry Pi 5 (always-on, Tailscale)
    ├── Cron: Daily note assessment via claude -p
    ├── MCP Filesystem: ~/notes, ~/Google Drive (via rclone)
    ├── MCP Google Drive: Direct Drive access
    ├── Git: Blog repo with worktree isolation
    └── Results: PRs created on GitHub for review
    ↕
GitHub (Actions for additional processing, Pages for hosting)
    ↕
Desktop (development, interactive Claude Code sessions)
```

**Tools needed:** Pi 5, Tailscale, Claude Code, rclone or Google Drive MCP, claude-code-scheduler plugin.

### Key Decision Points

| Question | Recommendation |
|----------|----------------|
| Where to run cron jobs? | **GitHub Actions** if < 2000 min/month; **Raspberry Pi** for more control |
| How to access notes? | **--add-dir** for interactive; **MCP Filesystem** for automated; **Google Drive MCP** for cloud-first |
| Mobile access? | **Blink Shell + Tailscale + Pi** for full terminal; **Claude iOS app** for quick tasks |
| Note assessment? | **Custom prompt** (see Section 7) with `claude -p` and `--json-schema` |
| Safety for automation? | **--allowedTools** whitelist over **--dangerously-skip-permissions** whenever possible |
