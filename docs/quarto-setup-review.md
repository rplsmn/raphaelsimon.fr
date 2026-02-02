# Review: `docs/quarto-setup-guide.md` (Quarto + raphaelsimon.fr)

This is a review of the setup guide from the perspective of a senior writer/blogger and tech lead: optimize for **low cognitive load**, **repeatability**, and a workflow that still feels good **6 months later**.

## Executive summary

The guide is already strong: it’s phased, copy/paste friendly, and covers the core needs (dark default, search, blog listing, RSS, static contact form).

The biggest opportunities are to:

- Make a single **Happy path** unmistakable (reduce choice overload).
- Make steps **idempotent** (safe to re-run without fear).
- Remove contradictions (GitHub URL mismatch, sample dates).
- Align more explicitly with the repo direction: **phone-first publishing**, **navigation from any entry page**, and keeping email/public contact **abuse-resistant**.

---

## What’s strong

- **Phased structure + checklists**: this is exactly what a future-you needs.
- **Good defaults**: Quarto website project, blog listing, RSS feed enabled, dark/light themes.
- **Local workflow explained** (`quarto preview` vs `quarto render`).
- **Pragmatic contact form** with a static provider.

---

## High-impact improvements

### 1) Put the Happy path first (and demote alternatives)

Right now, the deployment section offers multiple branches (manual upload vs git integration vs GH Actions to Cloudflare). That’s great for completeness but increases decision fatigue.

Recommend adding an early section like:

> **Happy path (recommended): GitHub Pages with `quarto publish gh-pages`**
>
> - Do not commit rendered output directories.
> - Publish to a `gh-pages` branch using Quarto’s native publishing.
> - Keep Cloudflare as a later migration option.

Then move Cloudflare-specific approaches into an “Appendix: Cloudflare Pages later”.

### 2) Add a GitHub Pages happy path (your current choice)

Since you want GitHub Pages now (Cloudflare later), the guide should present this as the mainline path, following Quarto’s official docs:

- Quarto supports three GH Pages options:
  1) render to `docs/` and commit it,
  2) `quarto publish` from your machine,
  3) GitHub Action to render + publish.

For your goals (simple, static, minimal maintenance), the **least messy diffs** are usually:

- Prefer **`quarto publish gh-pages`** and keep `/_site/` ignored.

Key guide changes suggested:

- Keep `.gitignore` ignoring `/_site/` (and `/.quarto/`).
- Ensure GitHub Pages is configured to use **branch: `gh-pages`** and **folder: `/`**.
- Add a short “first publish” command block:

```bash
quarto render
quarto publish gh-pages
```

And a “subsequent publishes” block:

```bash
quarto publish gh-pages
```

(Quarto will re-render by default; you can note `--no-render` as an advanced option.)

### 3) Make the init step safer: `quarto create project website .`

As written, this can be a footgun in an existing repo because it may overwrite or create starter files you didn’t intend.

Suggested improvement to the guide wording:

- If the repo is empty, fine.
- If not, add a warning: “This will create starter files; if you already have content, back it up / commit first.”

### 4) Make steps idempotent (“safe to re-run”)

A maintainer-friendly guide avoids steps that fail or confuse when repeated.

Examples:

- When creating directories/files: mention “If it already exists, skip.”
- When editing `_quarto.yml`: emphasize “merge carefully, don’t replace blindly.”

### 5) Fix inconsistencies: GitHub URL + sample post dates

- Canonical GitHub is: **https://github.com/rplsmn** (use it everywhere).
- Sample post dates should not freeze the site in time. Use **today**.

Suggested pattern:

- In the guide text: “Use today’s date (`YYYY-MM-DD`) in both folder name and frontmatter.”

### 6) Search shortcut: follow Quarto native behavior

Quarto’s built-in search overlay supports keyboard shortcuts. Per Quarto docs, defaults include: `s`, `f`, and `/`, and Quarto allows overriding via `keyboard-shortcut`.

Guide recommendation:

- If you want “least surprising”, **don’t override** the shortcuts; stick to native defaults.
- Only customize if you have a strong preference and have verified it works cross-platform.

So: remove the custom `keyboard-shortcut: ["?", "/", "k"]` suggestion unless you have tested it and want that behavior.

---

## Redundancies / places to tighten

- **Preview vs render** is repeated; keep one canonical section and reference it.
- **Deployment section** currently reads like a decision tree. Keep one recommended path; move others to appendices.
- **Verification checklists** are duplicated (local vs deployed). Consider one checklist with two scopes.

---

## Alignment with `.drafts/repo-init-direction.md`

Your direction emphasizes:

- phone-first publishing
- good site search
- navigation from any page back to home/blog/contact
- minimal maintenance

The guide already handles search and a navbar, but needs explicit guidance for:

- **phone-first publishing workflow** (see next section)
- **consistent navigation affordances** (navbar + footer + maybe an include on posts)

---

## Phone-first publishing (section to add)

Goal: be able to publish a post from your phone with minimal friction, while keeping the repo and build clean.

### Option A (recommended): GitHub mobile + write Markdown, publish via PR

1. On your phone, use the **GitHub mobile app**.
2. Create a new branch.
3. Add a folder under `blog/posts/YYYY-MM-DD-post-slug/`.
4. Create `index.qmd` (or `.md` if you prefer) with frontmatter.
5. Open a pull request.
6. Merge when ready; publishing happens from your normal workflow.

Why this works:

- No special tooling.
- You can save drafts in a branch.
- Review before publishing (even if it’s just you).

### Option B: “Notes → repo” via a single file

If you often write in a notes app first:

- Write the content in a note as plain Markdown.
- Copy into `blog/posts/YYYY-MM-DD-post-slug/index.qmd` in GitHub mobile.

### Suggested lightweight post template

```yaml
---
title: "Post title"
description: "One sentence summary"
date: "YYYY-MM-DD"  # today
categories: [tag1, tag2]
draft: true
---

Start writing here.
```

Then set `draft: false` when you merge/publish.

---

## Contact/email abuse note (optional but valuable)

Because you intend to show contact info on a public site:

- Prefer the **contact form** as the primary contact method.
- If you include an email address, consider using a **Proton alias** for `contact@` so it can be rotated if scraped.

---

## Concrete edits to make in the guide

1. Add an early “Happy path: GitHub Pages with Quarto publish” section (and make it the default deployment path).
2. Replace GitHub links with `https://github.com/rplsmn` everywhere.
3. Change sample post date instructions from a fixed date to **today**.
4. Keep Quarto search shortcuts native by default; document the defaults rather than overriding.
5. Add a “Phone-first publishing” section (use the one above).
6. Move Cloudflare content to an appendix (“later migration”).
