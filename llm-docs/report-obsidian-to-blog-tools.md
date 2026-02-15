# Research Report: Obsidian Notes to Blog Post Workflows

**Date:** 2026-02-15
**Scope:** Tools, plugins, automation patterns, and LLM integrations for turning Obsidian notes into published blog posts, with special attention to Quarto static sites.

---

## 1. Obsidian Plugins for Blog Publishing to Static Sites

As of early 2025, there are **48+ Obsidian community plugins** focused on publishing content. The most relevant ones for static-site workflows:

### Quarto-Specific

| Plugin | Description | URL |
|--------|-------------|-----|
| **Quarto Exporter** | Exports Obsidian notes to Quarto-compatible `.qmd` files. Handles date formatting (creation/modification), tag inclusion, output folder, and overwrite behavior. | [GitHub](https://github.com/AndreasThinks/obsidian-to-quarto-exporter) / [ObsidianStats](https://www.obsidianstats.com/plugins/quarto-exporter) |
| **qmd-as-md** | Enables editing and compiling `.qmd` Quarto files directly inside Obsidian, treating them as markdown. Avoids the export step entirely. | [GitHub](https://github.com/danieltomasz/qmd-as-md-obsidian) |

**Key challenges for Obsidian-to-Quarto:**
- Obsidian uses `[[wikilinks]]`; Quarto uses standard markdown links.
- Obsidian callout syntax (`> [!note]`) differs slightly from Quarto's.
- Frontmatter conventions are not fully compatible (null values, invalid arrays break Quarto).
- A Lua filter exists for [converting Obsidian callouts to Quarto format](https://gist.github.com/danieltomasz/87b1321e23c045309d2571f525f856cf).

### Hugo-Specific

| Plugin/Tool | Description | URL |
|-------------|-------------|-----|
| **Sync to Hugo** (Obsidian plugin) | Bridges Obsidian notes with Hugo, converting markdown and frontmatter into Hugo-compatible formats. | [ObsidianStats](https://www.obsidianstats.com/plugins/hugo-publish) |
| **obsidian-to-hugo** (CLI, Python) | Standalone CLI tool. Converts wikilinks to Hugo `ref` shortcodes, Obsidian marks to HTML `<mark>`, copies vault to Hugo content dir. Extensible with custom filters/processors. | [GitHub](https://github.com/devidw/obsidian-to-hugo) / [PyPI](https://pypi.org/project/obsidian-to-hugo/) |

### Multi-Generator / General

| Plugin | Description | URL |
|--------|-------------|-----|
| **Enveloppe** | Publishes notes to any GitHub repo (works with Jekyll, Hugo, MkDocs, etc.). Converts wikilinks to markdown links, handles folder structures, cleans deleted files. Excalidraw drawings auto-convert to SVG. Dataview queries rendered as plain markdown. Controlled via `share: true` frontmatter key. | [GitHub](https://github.com/Enveloppe/obsidian-enveloppe) / [Docs](https://enveloppe.ovh/) |
| **O2** | Converts Obsidian markdown to Jekyll and Docusaurus formats. | [ObsidianStats](https://www.obsidianstats.com/posts/2025-04-16-publish-plugins) |
| **Vault to Blog** | Generates a React SPA blog from an Obsidian vault. | [ObsidianStats](https://www.obsidianstats.com/plugins/vault-to-blog) |
| **Vitepress Plugin** | Preview and compile `.md` files using VitePress, Hugo, Hexo, or Docusaurus from inside Obsidian. | [ObsidianStats](https://www.obsidianstats.com/posts/2025-04-16-publish-plugins) |

**Assessment for this project:** Enveloppe is the most mature and flexible option for pushing selective notes to a GitHub-hosted Quarto site. The Quarto Exporter plugin is a more direct path but less feature-rich. A custom script bridging the two could be optimal.

---

## 2. Tools/Scripts for Syncing Obsidian Vaults

### Git-Based Sync

| Tool | Description | URL |
|------|-------------|-----|
| **Obsidian Git** (plugin) | The dominant solution. Automatic commit-and-sync on configurable intervals (e.g., every 10-15 min). Pull on open, push on close. Desktop is solid; **mobile is unstable** (uses isomorphic-git JS reimplementation, not native git). | [GitHub](https://github.com/Vinzent03/obsidian-git) |
| **obsidian-git-sync** (Hammerspoon) | macOS-specific. Auto pull/push on Obsidian open/close via Hammerspoon scripting. | [GitHub](https://github.com/stoneacher/obsidian-git-sync) |
| **Systemd timer** (Linux) | A systemd service + timer running `git pull && git add -A && git commit && git push` every 2 minutes. | [GozGeek](https://www.gozgeek.com/posts/2024/auto-syncing-git-based-obsidian-vault/) |
| **Launcher scripts** (.sh/.bat) | Simple: `git pull` before Obsidian opens, `git add/commit/push` after it closes. Works on macOS and Windows. | [dsebastien.net](https://www.dsebastien.net/how-i-synchronize-and-backup-my-obsidian-notes/) |

### Google Drive Sync

| Tool | Description | URL |
|------|-------------|-----|
| **obsidian-gdrive-sync** | One-click Google Drive sync setup. | [GitHub](https://github.com/stravo1/obsidian-gdrive-sync) |
| **Obsidian Google Drive** (antoniotejada) | Bidirectional vault sync with Google Drive. | [GitHub](https://github.com/antoniotejada/obsidian-google-drive) |
| **Google Drive plugin** (RichardX366) | Auto-syncs vault with Google Drive while Obsidian is open. Enables iOS access. | [GitHub](https://github.com/RichardX366/Obsidian-Google-Drive) |

### Mobile Git Workarounds

- **Android:** Use Termux with git scripts as a workaround. Guide: [Makeshift gist](https://gist.github.com/Makeshift/43c7ecb3f1c28a623ea4386552712114) and [Amir Pourmand](https://amirpourmand.ir/posts/2023/how-to-sync-obsidian/).
- **iOS:** Use a-shell for free automatic GitHub sync. Guide: [Obsidian Forum](https://forum.obsidian.md/t/mobile-automatic-sync-with-github-on-ios-for-free-via-a-shell/46150).
- **GitSync** (third-party app): Available on both Android and iOS, more stable than Obsidian Git's mobile mode.

---

## 3. Automation Patterns for Periodic Content Assessment

### GitHub Actions (Recommended for this project)

GitHub Actions supports `schedule` triggers using cron syntax. Relevant patterns:

- **Scheduled content review:** A GitHub Action runs on a cron schedule (e.g., weekly), uses Claude Code Action to scan a drafts folder, and opens issues or PRs for notes deemed ready.
- **Claude Code Action** (official): [GitHub](https://github.com/anthropics/claude-code-action) / [Marketplace](https://github.com/marketplace/actions/claude-code-action-official). Can be configured to review PR content, assess quality, and provide suggestions.
- **LLM-in-Actions pattern:** Separate parsing from LLM content review for accuracy and cost efficiency. See [Tony Baloney's guide](https://tonybaloney.github.io/posts/using-llm-in-github-actions.html).
- **Documentation automation:** A scheduled workflow reviews commits from the last 24 hours and maintains a documentation PR. See [Frank Bernhardt on Medium](https://medium.com/@fra.bernhardt/automate-your-documentation-with-claude-code-github-actions-a-step-by-step-guide-2be2d315ed45).

### Other CI/CD Approaches

| Platform | Scheduling | Notes |
|----------|-----------|-------|
| **GitLab CI** | `schedules:` in `.gitlab-ci.yml` | Pipeline schedules with full cron syntax. |
| **CircleCI** | Scheduled pipelines | Benefits include running resource-heavy jobs off-peak. |
| **Systemd timers** | On-server cron alternative | More reliable than cron for long-running tasks. |

### Proposed Pattern for This Project

```yaml
# .github/workflows/assess-drafts.yml
name: Assess Draft Readiness
on:
  schedule:
    - cron: '0 9 * * 1'  # Every Monday at 9 AM UTC
  workflow_dispatch: {}

jobs:
  assess:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: anthropics/claude-code-action@v1
        with:
          prompt: |
            Review all files in drafts/ folder.
            For each note, assess:
            - Completeness (has intro, body, conclusion)
            - Coherence (flows logically)
            - Readiness score (1-10)
            Create a GitHub issue listing notes scored 7+ as "ready for review".
```

---

## 4. LLM-Based "Readiness" Assessment of Notes

### Existing Projects

| Project | Description | URL |
|---------|-------------|-----|
| **Corti.com system** | Full CI/CD pipeline treating an Obsidian vault as a production system. Claude Code serves as the intelligent layer bridging manual curation and automated content management. Includes AI-powered content enhancement and multi-format publishing pipelines. | [corti.com](https://corti.com/building-an-ai-powered-knowledge-management-system-automating-obsidian-with-claude-code-and-ci-cd-pipelines/) |
| **obsidian-claude** (ZanderRuss) | 31 commands, 27 agents, 19 AI skills. Full research workflow. Includes agents for note organization, weekly review, goal alignment, inbox processing. | [GitHub](https://github.com/ZanderRuss/obsidian-claude) |
| **obsidian-claude-pkm** (ballred) | Starter kit with `/daily`, `/weekly`, `/push`, `/onboard` commands. Custom agents for note-organizer, weekly-reviewer, goal-aligner, inbox-processor. Hooks for auto-commit. | [GitHub](https://github.com/ballred/obsidian-claude-pkm) |

### LLM-as-Judge Pattern

The "LLM-as-a-judge" approach from ML evaluation can be directly applied to note readiness:
- Feed the LLM a note, a rubric (completeness, coherence, audience fit, etc.), and ask for a structured score.
- This is well-documented in the [n8n blog](https://blog.n8n.io/llm-evaluation-framework/) and [Arize AI guide](https://arize.com/llm-evaluation/).

### Custom Assessment Criteria for Blog Readiness

A practical rubric for note-to-blog readiness assessment:
1. **Structure:** Has title, introduction, body sections, conclusion.
2. **Completeness:** No `TODO`, `TBD`, `???` placeholders. All arguments supported.
3. **Audience:** Written for external readers (not just personal shorthand).
4. **Length:** Meets minimum word count for a blog post (e.g., 500+ words).
5. **Links/References:** External claims are sourced.
6. **Metadata:** Has appropriate frontmatter (categories, tags, description).

---

## 5. Mobile-First Blogging Workflows

### The Mobile Challenge

Obsidian's mobile app has near-parity with desktop for editing but is **weak for quick capture** (the 2025 Obsidian Report Card at [practicalpkm.com](https://practicalpkm.com/2025-obsidian-report-card/) calls this out specifically). Common workarounds:

### Recommended Mobile-First Stack

| Layer | Tool | Why |
|-------|------|-----|
| **Quick Capture** | **Drafts** (iOS/Mac) | Opens instantly, captures text before you forget. Supports dictation, multiple export actions. Can push to Obsidian vault via actions. |
| **Writing/Editing** | **Obsidian Mobile** | Full editing experience. iCloud or Git sync keeps it in sync with desktop. |
| **Sync** | **iCloud** (iOS) or **GitSync app** (Android/iOS) | Most stable mobile sync options. Obsidian Git plugin is unreliable on mobile. |
| **Review/Publish** | **GitHub Mobile** or **Browser** | Review PRs on phone, approve publications. |

### Key Workflow

1. **Capture** on phone with Drafts (voice or text) -- idea goes to inbox.
2. **Triage** in Obsidian Mobile -- move from inbox to drafts folder, add initial structure.
3. **Write** in Obsidian (desktop or mobile) -- flesh out the note.
4. **Sync** via Git (desktop) or iCloud (mobile).
5. **Assess** via scheduled GitHub Action (automated) or Claude Code (manual).
6. **Publish** via PR review on phone.

### Relevant Links
- [Drafts app](https://getdrafts.com/)
- [Gautham Shankar's workflow](https://ingau.me/blog/how-i-write-my-blogs-in-obsidian-and-publish-instantly/)
- [Cassidy Williams' publishing workflow](https://cassidoo.co/post/publishing-from-obsidian/)
- [Matt Giaro's blogging with Obsidian tutorial](https://mattgiaro.com/blogging-obsidian/)

---

## 6. Obsidian + Claude Code / LLM CLI Integrations

This is an **active and rapidly growing** space (as of early 2026).

### Plugins Bringing Claude Code Into Obsidian

| Plugin | Description | URL |
|--------|-------------|-----|
| **Agent Client** | Brings Claude Code, Codex, and Gemini CLI inside Obsidian as sidebar panels. | [Obsidian Forum](https://forum.obsidian.md/t/new-plugin-agent-client-bring-claude-code-codex-gemini-cli-inside-obsidian/108448) |
| **Obsidian-AI-CLI** | Integrates Claude Code and Gemini CLI into Obsidian. Executes AI commands through sidebar panels, auto-passes file context and selected text. | [GitHub](https://github.com/blackdragonbe/obsidian-ai-cli) |
| **Claudesidian** | Pre-configured vault structure designed to work seamlessly with Claude Code. Turns vault into AI-powered second brain. | [GitHub](https://github.com/heyitsnoah/claudesidian) |
| **obsidian-claude-code-mcp** | Connects Claude Code to Obsidian via MCP (Model Context Protocol). Supports WebSocket for Claude Code and HTTP/SSE for Claude Desktop. | [GitHub](https://github.com/iansinnott/obsidian-claude-code-mcp) |
| **obsidian-ai-agent** | Integrated AI agent (Claude Code) plugin for Obsidian. | [GitHub](https://github.com/m-rgba/obsidian-ai-agent) |

### Full PKM Systems with Claude Code

| System | Features | URL |
|--------|----------|-----|
| **obsidian-claude** (ZanderRuss) | 31 commands, 27 agents, 19 skills, 4 hooks, 17 plugins. PARA method. Full research workflow with MCP integration. | [GitHub](https://github.com/ZanderRuss/obsidian-claude) |
| **obsidian-claude-pkm** (ballred) | Starter kit. `/daily`, `/weekly`, `/push`, `/onboard` skills. Auto-commit hooks. Note organization agents. Status line in terminal. | [GitHub](https://github.com/ballred/obsidian-claude-pkm) |
| **Knowledge Vault** (naushadzaman) | Replaces Evernote, Notion, Asana, Otter.ai with local markdown + Claude Code skills + persistent context. | [GitHub Gist](https://gist.github.com/naushadzaman/164e85ec3557dc70392249e548b423e9) |

### Key Integration Patterns

1. **MCP Server:** Obsidian runs an MCP server; Claude Code connects to it for vault read/write operations.
2. **GitHub-as-bridge:** Vault synced to GitHub. Claude Code Action runs on issues/PRs. Create a GitHub issue, tag @claude, Claude does research and creates notes.
3. **Firecrawl integration:** Claude Code + Firecrawl fetches web content, saves to vault. Claude searches/analyzes thousands of saved articles.
4. **Direct CLI execution:** Claude Code runs directly in the vault directory, reading/writing markdown files. The `CLAUDE.md` in the vault root provides context.

### Relevant Articles
- [Kyle Gao: Using Claude Code with Obsidian](https://kyleygao.com/blog/2025/using-claude-code-with-obsidian/)
- [XDA Developers: Claude Code inside Obsidian](https://www.xda-developers.com/claude-code-inside-obsidian-and-it-was-eye-opening/)
- [Corti.com: AI-Powered Knowledge Management](https://corti.com/building-an-ai-powered-knowledge-management-system-automating-obsidian-with-claude-code-and-ci-cd-pipelines/)
- [QED42: Integrating Obsidian MCP with Claude](https://www.qed42.com/insights/supercharge-your-knowledge-management---integrating-obsidian-mcp-with-claude)

---

## 7. The Digital Garden Movement

### Philosophy

Digital gardens are the anti-blog: notes grow and connect over time rather than being published once and forgotten. Key principles:
- **Learning in public:** Share work-in-progress thinking.
- **No publish dates:** Content is timeless, always evolving.
- **Bi-directional links:** Notes form a knowledge graph.
- **Low pressure:** No need for polished "posts" -- notes at various maturity levels coexist.

### Tools

| Tool | Description | URL |
|------|-------------|-----|
| **Obsidian Digital Garden** (plugin) | Free, open source. Publish selected notes with `dg-publish: true` frontmatter. Only marked notes leave the vault. Hosted on Vercel/Netlify. | [Docs](https://dg-docs.ole.dev/) / [GitHub](https://github.com/oleeskild/obsidian-digital-garden) |
| **Quartz** | Static-site generator optimized for Obsidian. Backlinks, graph visualization, full-text search, RSS feed. The only Obsidian publishing tool with RSS. Quartz v4 is a full rewrite. | [Site](https://quartz.jzhao.xyz/) / [ObsidianStats](https://www.obsidianstats.com/tags/digital-garden) |
| **Flowershow** | Publish Obsidian notes to a personalized site on Vercel. Integrates with GitHub via Enveloppe plugin. | [flowershow.app](https://flowershow.app/blog/how-to-publish-vault-with-enveloppe-plugin) |
| **Quartz Syncer** (plugin) | Bridges Obsidian with Quartz. Publish selected notes directly from vault to Quartz GitHub repo via GitHub REST API. | [ObsidianStats](https://www.obsidianstats.com/tags/digital-garden) |

### Hybrid Blog + Garden Approach

Several practitioners maintain both:
- A **digital garden** for ongoing notes (using Quartz or Digital Garden plugin).
- A **blog** for polished posts (using Hugo, Quarto, etc.).
- Notes "graduate" from garden to blog when they reach maturity.

This is the pattern most relevant to this project: Obsidian vault as garden, Quarto site as blog, with an LLM-assisted assessment step in between.

### Relevant Articles
- [Digital Gardening in 2025: The Return of the Curated Web](https://medium.com/@theo-james/digital-gardening-in-2025-the-return-of-the-curated-web-3ae36f7add77)
- [Building a Digital Garden with Obsidian and Quartz](https://notes.hamatti.org/technology/building-a-digital-garden-with-obsidian-and-quartz)
- [Building a Digital Garden with Obsidian and Astro](https://www.emgoto.com/obsidian-digital-garden/)
- [Ian O'Byrne: How I Built My Digital Garden](https://wiobyrne.com/how-i-built-my-digital-garden/)

---

## Summary: Most Relevant Tools for This Project (raphaelsimon.fr)

Given that this is a Quarto static site hosted on GitHub Pages, the most actionable findings are:

| Need | Recommended Tool | Why |
|------|-----------------|-----|
| **Obsidian to Quarto export** | Quarto Exporter plugin + custom Lua filter for callouts | Direct `.md` to `.qmd` conversion with frontmatter handling |
| **Alternative: edit in-place** | qmd-as-md plugin | Write `.qmd` directly in Obsidian, no export step |
| **Selective publishing** | Enveloppe plugin | Push only `share: true` notes to the GitHub repo |
| **Vault sync** | Obsidian Git (desktop) + iCloud (mobile) | Most stable combo |
| **Mobile capture** | Drafts app | Instant capture, then triage to Obsidian |
| **Automated readiness check** | GitHub Actions + Claude Code Action | Weekly cron: scan drafts folder, score notes, open issues |
| **LLM integration** | Claude Code in vault directory | Direct CLI access to vault markdown files |
| **Full PKM starter** | obsidian-claude-pkm (ballred) | If a turnkey system is desired |
