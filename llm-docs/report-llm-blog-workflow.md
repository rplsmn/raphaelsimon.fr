# Research Report: LLM-Assisted Blogging Workflow for raphaelsimon.fr

**Date:** 2026-02-15
**Context:** Finding the best workflow to turn messy Obsidian notes into published blog posts on a Quarto site, with automation, mobile-first authoring, and an always-on RPi in the mix.

**Supporting reports (detailed references):**
- `report-simon-willison-llm-blogging-workflow.md` -- Simon Willison's approach
- `report-obsidian-to-blog-tools.md` -- Obsidian plugins and tools landscape
- `report-llm-content-pipeline-automation.md` -- Automation patterns (Claude Code, RPi, GitHub Actions, MCP)

---

## TL;DR -- What I Recommend

Your workflow has three problems to solve:

1. **The notes-to-repo bridge** -- getting Obsidian notes into Claude Code's reach without committing them
2. **The maturity assessment** -- knowing when a messy note has enough meat for an article
3. **The phone-to-publish pipeline** -- writing on the go, triggering drafts, reviewing PRs

Here's the approach I'd suggest, in order of what to build first:

### Phase 1: Immediate wins (today)

- **`--add-dir`** to point Claude Code at your Obsidian vault when working on the blog repo. No sync, no commit, no copy-paste:
  ```bash
  claude --add-dir /path/to/obsidian/vault
  ```
- **A Claude skill** (`notes-to-draft`) in this repo that reads a note, assesses maturity, and either drafts an article or explains what's missing. See the [skill design](#the-claude-skill) below.
- **Your existing VPS + Termius workflow** already works for mobile. Just SSH in, `cd` to the blog repo, run `claude --add-dir ...` and invoke the skill.

### Phase 2: RPi automation (your cron idea, refined)

- **rclone** on your RPi to sync a subfolder of your Obsidian vault from iCloud/Google Drive. Cron runs every 30 min.
- **A cron script** on the RPi that runs `claude -p` against new/changed notes, scores them, and pushes results to a `drafts-assessment.json` file in the blog repo.
- **GitHub Actions** picks up the push, opens an issue summarizing which notes are ready.
- You review on your phone via GitHub iOS.

### Phase 3: Full pipeline (when you have the rhythm down)

- **MCP Filesystem server** configured in `~/.claude/mcp.json` to always expose your notes dir to Claude Code -- no `--add-dir` needed.
- **Scheduled GitHub Action** using `anthropics/claude-code-action` for weekly note assessment (alternative to RPi cron if you prefer cloud-only).
- **Enveloppe** Obsidian plugin to selectively push `share: true` notes to the blog repo's `drafts/` folder, removing the rclone middleman.

---

## What Simon Willison Does (and Doesn't Do)

You remembered right -- Simon writes extensively about LLMs and blogging. But the key finding is: **he does NOT let LLMs write his blog posts.**

His reasoning: "I don't like letting LLMs write for me." He considers credibility paramount and notes that sophisticated readers detect LLM prose. With 22+ years of writing experience, he doesn't need LLMs to generate text.

**What he does use LLMs for:**
- Thesaurus and proofreading
- Checking arguments for logical holes
- First-draft alt text for images (via a Claude Project, then manually refined)
- Summarizing long discussions (HN threads, transcripts) for research

**His automation isn't about writing -- it's about distribution.** He automated his Substack newsletter to a 2-minute process using an Observable notebook + Datasette/SQLite pipeline that generates formatted HTML from his blog's content database. Same for his weeknotes.

**His philosophy:** "Aim to hit publish while you are still actively unhappy with what you have written, because the only alternative is a huge folder full of drafts."

**Relevant tools he built:**
- [`llm`](https://github.com/simonw/llm) -- CLI tool for running prompts against LLMs, logs everything to SQLite
- [`strip-tags`](https://github.com/simonw/strip-tags) -- strips HTML, CSS-selector filtering
- [`files-to-prompt`](https://github.com/simonw/files-to-prompt) -- concatenates files into a prompt
- All composable via Unix pipes: `curl URL | strip-tags .article | llm -s 'Summarize'`

**Key sources:**
- [Simon Willison on Technical Blogging](https://writethatblog.substack.com/p/simon-willison-on-technical-blogging)
- [Semi-automating a Substack newsletter](https://simonwillison.net/2023/Apr/4/substack-observable/)
- [My approach to running a link blog](https://simonwillison.net/2024/Dec/22/link-blog/)

---

## The Notes-to-Repo Bridge Problem

Your core constraint: Obsidian notes live outside this repo, and you don't want to commit them. Five solutions exist, ranked by fit for your setup:

### 1. `--add-dir` flag (best for interactive use)

```bash
# Launch Claude Code with access to both repos
claude --add-dir ~/path/to/obsidian-vault
```

Claude Code gains read/write access to the vault without it being part of the git repo. Works today, no setup needed. This is the fastest path to replacing your copy-paste workflow.

### 2. MCP Filesystem Server (best for automated/persistent access)

```json
// .claude/mcp.json in the blog repo
{
  "mcpServers": {
    "notes": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/path/to/obsidian/vault"]
    }
  }
}
```

Always available when working in this repo. Claude sees your notes via MCP tools (`read_text_file`, `search_files`, etc.).

### 3. Symlink + .gitignore (simple but limited)

```bash
ln -s ~/path/to/obsidian-vault /home/raph/raphaelsimon.fr/notes
echo "notes" >> .gitignore
```

### 4. rclone on RPi (best for your cron automation idea)

```bash
# Sync Obsidian vault subfolder from iCloud/Google Drive to RPi
rclone sync gdrive:Notes/blog-seeds ~/content-pipeline/incoming/ --config ~/.config/rclone/rclone.conf
```

This is what makes the RPi automation possible. rclone supports iCloud (via WebDAV), Google Drive, Dropbox, etc.

### 5. Google Drive MCP Server (cloud-native, more complex)

Multiple MCP servers exist for Google Drive access ([googleDriveMCP](https://github.com/michaelpine25/googleDriveMCP), [google-docs-mcp](https://github.com/a-bonus/google-docs-mcp)). Requires Google Cloud OAuth setup. Powerful but heavier than rclone.

---

## The Maturity Assessment

No off-the-shelf tool exists for "is this note ready to be a blog post?" -- this is a gap in the ecosystem. But the pattern is well-established (LLM-as-a-judge) and easy to build.

### The Claude Skill

Here's the skill I'd recommend creating in `.claude/skills/notes-to-draft.md`:

**Trigger:** User invokes `/notes-to-draft` with a path to an Obsidian note
**Behavior:**

1. Read the note (via `--add-dir` or MCP)
2. Parse Obsidian tags and headings for context
3. Score the note on a rubric:
   - **Core thesis** (is there a clear argument?)
   - **Supporting evidence** (enough examples/data?)
   - **Structure potential** (can it flow as an article?)
   - **Unique value** (not just restating known things?)
   - **Completeness** (obvious gaps needing more research?)
4. If score >= 7/10: Draft the article in Quarto `.qmd` format, respecting the site's frontmatter conventions and bilingual structure
5. If score < 7: Return a structured assessment -- what's there, what's missing, what would make it publishable
6. Either way, never publish automatically -- create a draft PR for review

### For Automated Assessment (RPi cron or GitHub Actions)

```bash
#!/bin/bash
# assess-notes.sh -- run on RPi via cron
for note in ~/content-pipeline/incoming/*.md; do
  cat "$note" | claude -p \
    "Assess this Obsidian note for blog readiness. Return JSON." \
    --output-format json \
    --json-schema '{"type":"object","properties":{"title":{"type":"string"},"score":{"type":"number"},"recommendation":{"type":"string","enum":["ready","needs_work","seed_only"]},"missing":{"type":"array","items":{"type":"string"}},"outline":{"type":"array","items":{"type":"string"}}}}'
done
```

---

## The Mobile Pipeline

Your Termius + VPS + Tailscale setup is already strong. Here's how to optimize it for blog posting:

### Current Flow (works today)
```
Phone (Obsidian) → write notes
Phone (Termius) → SSH to VPS → claude --add-dir /vault → /notes-to-draft
Phone (GitHub iOS) → review PR → merge → GH Pages deploys
Phone (Safari) → preview on Tailscale localhost
```

### Enhanced Flow (with RPi)
```
Phone (Obsidian) → write notes → iCloud/GDrive sync
RPi (cron) → rclone sync → assess notes → push results
Phone (GitHub iOS) → notification: "3 notes ready for drafting"
Phone (Termius) → SSH to VPS or RPi → claude /notes-to-draft → creates PR
Phone (GitHub iOS) → review draft PR → merge
```

### Mobile App Alternatives Worth Knowing About

| App | Why it's interesting |
|-----|---------------------|
| **Blink Shell** | Mosh support (connections survive sleep/wake). Better than Termius for flaky mobile connections. |
| **Moshi** | iOS terminal with push notifications for agent events -- knows when Claude finishes a task. |
| **Claude Code iOS** | Anthropic added Claude Code to the iOS app in late 2025. Native, no SSH needed. Worth checking if it fits your workflow. |

---

## What Others Are Doing (Notable Projects)

### Obsidian + Claude Code PKM Systems

Several projects treat an Obsidian vault as a full production system with Claude Code:

- **[obsidian-claude-pkm](https://github.com/ballred/obsidian-claude-pkm)** (ballred) -- Starter kit with `/daily`, `/weekly`, `/push` commands, auto-commit hooks, and note organization agents. Closest to what you're building.
- **[obsidian-claude](https://github.com/ZanderRuss/obsidian-claude)** (ZanderRuss) -- 31 commands, 27 agents, 19 skills. Full research workflow. Overkill but interesting to borrow from.
- **[Corti.com's system](https://corti.com/building-an-ai-powered-knowledge-management-system-automating-obsidian-with-claude-code-and-ci-cd-pipelines/)** -- Full CI/CD pipeline treating an Obsidian vault as a production system. Most ambitious approach documented publicly.

### Obsidian-to-Quarto Specifically

- **[Quarto Exporter](https://github.com/AndreasThinks/obsidian-to-quarto-exporter)** plugin -- exports `.md` to `.qmd` with frontmatter handling
- **[qmd-as-md](https://github.com/danieltomasz/qmd-as-md-obsidian)** plugin -- edit `.qmd` files directly in Obsidian (no export step)
- **[Enveloppe](https://github.com/Enveloppe/obsidian-enveloppe)** -- push `share: true` notes to any GitHub repo. Works with Quarto. Converts wikilinks to markdown links.

### The Digital Garden Hybrid

The most philosophically aligned pattern: maintain a **private digital garden** (Obsidian vault) and a **public blog** (Quarto site). Notes "graduate" from garden to blog when they reach maturity. The LLM is the judge of maturity, and the skill/automation handles the format conversion.

---

## Concrete Next Steps

1. **Today:** Create the `notes-to-draft` Claude skill in this repo. Test it by running `claude --add-dir /path/to/vault` and invoking the skill on your LLM/AI note.

2. **This week:** Set up rclone on your RPi to sync a "blog-seeds" subfolder from wherever your Obsidian vault lives (iCloud, Google Drive).

3. **Next week:** Write the `assess-notes.sh` cron script for the RPi. Start with daily runs, tune the assessment prompt based on results.

4. **When it works:** Add a GitHub Action that picks up assessment results and opens issues. Review on your phone.

5. **Polish:** Create the MCP filesystem config so Claude always sees your notes. Build the full draft-to-PR pipeline in the skill.

---

## Key Sources

### Simon Willison
- [Simon Willison on Technical Blogging](https://writethatblog.substack.com/p/simon-willison-on-technical-blogging)
- [Semi-automating a Substack newsletter](https://simonwillison.net/2023/Apr/4/substack-observable/)
- [Weeknotes: A new llm CLI tool](https://simonwillison.net/2023/Apr/4/llm/)
- [My approach to running a link blog](https://simonwillison.net/2024/Dec/22/link-blog/)
- [GitHub - simonw/llm](https://github.com/simonw/llm)

### Obsidian + Claude Code
- [Corti.com: AI-Powered Knowledge Management](https://corti.com/building-an-ai-powered-knowledge-management-system-automating-obsidian-with-claude-code-and-ci-cd-pipelines/)
- [obsidian-claude-pkm](https://github.com/ballred/obsidian-claude-pkm)
- [obsidian-claude](https://github.com/ZanderRuss/obsidian-claude)
- [XDA: Claude Code inside Obsidian](https://www.xda-developers.com/claude-code-inside-obsidian-and-it-was-eye-opening/)

### Automation
- [Claude Code Action](https://github.com/anthropics/claude-code-action)
- [claude-code-scheduler](https://github.com/jshchnz/claude-code-scheduler)
- [Using LLMs in GitHub Actions](https://tonybaloney.github.io/posts/using-llm-in-github-actions.html)
- [Claude Code headless docs](https://code.claude.com/docs/en/headless)

### Obsidian Publishing
- [Quarto Exporter](https://github.com/AndreasThinks/obsidian-to-quarto-exporter)
- [Enveloppe](https://github.com/Enveloppe/obsidian-enveloppe)
- [qmd-as-md](https://github.com/danieltomasz/qmd-as-md-obsidian)

### Mobile Workflows
- [Blink Shell](https://blink.sh)
- [Moshi](https://getmoshi.app)
- [Claude Code on phone](https://sealos.io/blog/claude-code-on-phone)
