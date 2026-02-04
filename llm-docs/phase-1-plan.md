# Phase 1: Structure Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Reorganize the site into `/en/` and `/fr/` subdirectories with language-aware configuration, root redirect, and successful build of both language versions.

**Architecture:** Create symmetric language directories, move existing content to `/en/`, duplicate structure to `/fr/` (content stays English temporarily), configure per-language `_metadata.yml`, update root `_quarto.yml` to reference language subdirectories, and add root `index.html` for browser-based language detection redirect.

**Tech Stack:** Quarto, HTML, YAML

---

## Pre-Implementation Checklist

- [ ] Verify on `main` branch with clean working directory
- [ ] Create feature branch: `git checkout -b feature/multilang-phase-1`

---

## Task 1: Create Language Directory Structure

**Files:**

- Create: `en/` directory
- Create: `fr/` directory
- Create: `en/blog/` directory
- Create: `en/blog/posts/` directory
- Create: `fr/blog/` directory
- Create: `fr/blog/posts/` directory

**Step 1: Create all directories**

```bash
mkdir -p en/blog/posts fr/blog/posts
```

**Step 2: Verify structure**

```bash
ls -la en/ fr/
```

Expected: Both directories exist with `blog/posts/` subdirectories.

**Step 3: Commit**

```bash
git add en/ fr/
git commit -m "chore: create language directory structure for en/fr"
```

---

## Task 2: Move Root Content Files to /en/

**Files:**

- Move: `index.qmd` → `en/index.qmd`
- Move: `about.qmd` → `en/about.qmd`
- Move: `contact.qmd` → `en/contact.qmd`
- Move: `thanks.qmd` → `en/thanks.qmd`

**Step 1: Move files**

```bash
git mv index.qmd en/index.qmd
git mv about.qmd en/about.qmd
git mv contact.qmd en/contact.qmd
git mv thanks.qmd en/thanks.qmd
```

**Step 2: Verify moves**

```bash
ls en/*.qmd
```

Expected: `en/about.qmd  en/contact.qmd  en/index.qmd  en/thanks.qmd`

**Step 3: Commit**

```bash
git commit -m "refactor: move root content files to /en/ directory"
```

---

## Task 3: Move Blog Content to /en/blog/

**Files:**

- Move: `blog/index.qmd` → `en/blog/index.qmd`
- Move: `blog/_metadata.yml` → `en/blog/_metadata.yml`
- Move: `blog/posts/2026-02-02-hello-world/` → `en/blog/posts/2026-02-02-hello-world/`

**Step 1: Move blog index and metadata**

```bash
git mv blog/index.qmd en/blog/index.qmd
git mv blog/_metadata.yml en/blog/_metadata.yml
```

**Step 2: Move blog posts directory**

```bash
git mv blog/posts/2026-02-02-hello-world en/blog/posts/
```

**Step 3: Remove empty blog directory**

```bash
rmdir blog/posts blog
```

**Step 4: Verify structure**

```bash
ls -la en/blog/
ls -la en/blog/posts/
```

Expected: `en/blog/` contains `index.qmd`, `_metadata.yml`, and `posts/` directory with `2026-02-02-hello-world/`.

**Step 5: Commit**

```bash
git add -A
git commit -m "refactor: move blog content to /en/blog/ directory"
```

---

## Task 4: Create French Directory Structure (Copy from English)

**Files:**

- Create: `fr/index.qmd` (copy from `en/index.qmd`)
- Create: `fr/about.qmd` (copy from `en/about.qmd`)
- Create: `fr/contact.qmd` (copy from `en/contact.qmd`)
- Create: `fr/thanks.qmd` (copy from `en/thanks.qmd`)
- Create: `fr/blog/index.qmd` (copy from `en/blog/index.qmd`)
- Create: `fr/blog/_metadata.yml` (copy from `en/blog/_metadata.yml`)
- Create: `fr/blog/posts/2026-02-02-hello-world/` (copy from `en/blog/posts/`)

**Step 1: Copy all English content to French**

```bash
cp en/index.qmd fr/index.qmd
cp en/about.qmd fr/about.qmd
cp en/contact.qmd fr/contact.qmd
cp en/thanks.qmd fr/thanks.qmd
cp en/blog/index.qmd fr/blog/index.qmd
cp en/blog/_metadata.yml fr/blog/_metadata.yml
cp -r en/blog/posts/2026-02-02-hello-world fr/blog/posts/
```

**Step 2: Verify French structure matches English**

```bash
diff <(ls -R en/) <(ls -R fr/)
```

Expected: No output (structures are identical).

**Step 3: Commit**

```bash
git add fr/
git commit -m "chore: duplicate English content structure to French directory"
```

---

## Task 5: Create English Language Metadata

**Files:**

- Create: `en/_metadata.yml`

**Step 1: Create the file with content**

Create `en/_metadata.yml` with:

```yaml
lang: en
author: "Raphaël Simon"
```

**Step 2: Verify file exists and content is correct**

```bash
cat en/_metadata.yml
```

Expected output:

```
lang: en
author: "Raphaël Simon"
```

**Step 3: Commit**

```bash
git add en/_metadata.yml
git commit -m "feat: add English language metadata configuration"
```

---

## Task 6: Create French Language Metadata

**Files:**

- Create: `fr/_metadata.yml`

**Step 1: Create the file with content**

Create `fr/_metadata.yml` with:

```yaml
lang: fr
author: "Raphaël Simon"
```

**Step 2: Verify file exists and content is correct**

```bash
cat fr/_metadata.yml
```

Expected output:

```
lang: fr
author: "Raphaël Simon"
```

**Step 3: Commit**

```bash
git add fr/_metadata.yml
git commit -m "feat: add French language metadata configuration"
```

---

## Task 7: Update Root _quarto.yml

**Files:**

- Modify: `_quarto.yml`

**Step 1: Read current _quarto.yml to understand structure**

Read the file to identify:

- Current `website:` navbar configuration
- Current footer configuration
- Any hardcoded paths to root-level .qmd files

**Step 2: Update _quarto.yml**

The key changes needed:

1. Remove `lang: en` from root (languages now in subdirectory `_metadata.yml`)
2. Update navbar links to use `/en/` paths (will be relative within each language)
3. Keep shared configuration (theme, search, social icons) at root level

Replace the existing `_quarto.yml` with:

```yaml
project:
  type: website
  output-dir: _site

website:
  title: "Raphaël Simon"
  site-url: https://raphaelsimon.fr
  favicon: images/favicon.jpg
  search:
    location: navbar
    type: overlay
  navbar:
    background: dark
    left:
      - text: "Blog"
        href: blog/index.qmd
      - text: "About"
        href: about.qmd
      - text: "Contact"
        href: contact.qmd
    right:
      - icon: github
        href: https://github.com/raphaelsimon
        aria-label: GitHub
      - icon: linkedin
        href: https://www.linkedin.com/in/raphaelsimon-md/
        aria-label: LinkedIn
      - icon: cloud
        href: https://bsky.app/profile/raphaelsimon.fr
        aria-label: Bluesky
      - icon: rss
        href: blog/index.xml
        aria-label: RSS
  page-footer:
    left: |
      © 2026 Raphaël Simon
    right:
      - icon: github
        href: https://github.com/raphaelsimon
        aria-label: GitHub
      - icon: envelope
        href: mailto:contact@raphaelsimon.fr
        aria-label: Email
  back-to-top-navigation: true

format:
  html:
    theme:
      dark: darkly
      light: flatly
    css: styles.css
    toc: true
    code-copy: true
    code-overflow: wrap
```

**Important notes:**

- Navbar `href` values are relative (e.g., `blog/index.qmd` not `/en/blog/index.qmd`)
- This works because Quarto resolves paths relative to the current page's location
- When rendering `/en/index.qmd`, `blog/index.qmd` resolves to `/en/blog/index.qmd`
- When rendering `/fr/index.qmd`, `blog/index.qmd` resolves to `/fr/blog/index.qmd`

**Step 3: Verify YAML syntax is valid**

```bash
python3 -c "import yaml; yaml.safe_load(open('_quarto.yml'))"
```

Expected: No output (valid YAML).

**Step 4: Commit**

```bash
git add _quarto.yml
git commit -m "refactor: update _quarto.yml for language subdirectory structure"
```

---

## Task 8: Fix Internal Links in English Content

**Files:**

- Modify: `en/about.qmd` (fix contact link)
- Modify: `en/thanks.qmd` (fix home link)
- Modify: `en/index.qmd` (fix any internal links)

**Step 1: Read and update en/about.qmd**

Read the file. Find any links like `[contact](contact.qmd)` - these should remain as-is since they're relative and will resolve correctly within `/en/`.

Check for any absolute paths like `/contact.qmd` that need updating.

**Step 2: Read and update en/thanks.qmd**

Read the file. The home link should be relative: `[home](index.qmd)` or `[home](/)` depending on current implementation.

If it uses `/` for home, update to use `index.qmd` (relative).

**Step 3: Read and update en/index.qmd**

Read the file. Check the listing configuration points to correct relative path for blog posts.

Verify the listing path is `blog/posts` (relative, not `/blog/posts` or `/en/blog/posts`).

**Step 4: Verify no broken internal links**

```bash
grep -r "href.*\.qmd" en/ --include="*.qmd"
```

Review output for any absolute paths that need fixing.

**Step 5: Commit (if changes were made)**

```bash
git add en/
git commit -m "fix: update internal links in English content for new structure"
```

---

## Task 9: Fix Internal Links in French Content

**Files:**

- Modify: `fr/about.qmd`
- Modify: `fr/thanks.qmd`
- Modify: `fr/index.qmd`

**Step 1: Apply same link fixes as English**

French content was copied from English, so apply identical fixes.

**Step 2: Verify no broken internal links**

```bash
grep -r "href.*\.qmd" fr/ --include="*.qmd"
```

**Step 3: Commit (if changes were made)**

```bash
git add fr/
git commit -m "fix: update internal links in French content for new structure"
```

---

## Task 10: Create Root Redirect index.html

**Files:**

- Create: `index.html`

**Step 1: Create the redirect file**

Create `index.html` at project root with:

```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Redirecting...</title>
  <script>
    const lang = navigator.language?.startsWith('fr') ? 'fr' : 'en';
    window.location.replace('/' + lang + '/');
  </script>
  <noscript>
    <meta http-equiv="refresh" content="0;url=/en/" />
  </noscript>
</head>
<body>
  <p>Redirecting... <a href="/en/">Click here</a> if not redirected.</p>
</body>
</html>
```

**Step 2: Verify file content**

```bash
cat index.html
```

Expected: HTML content with JavaScript language detection.

**Step 3: Commit**

```bash
git add index.html
git commit -m "feat: add root redirect with browser language detection"
```

---

## Task 11: Update _quarto.yml to Include Root index.html in Output

**Files:**

- Modify: `_quarto.yml`

**Step 1: Add resources configuration**

Add to the `project:` section in `_quarto.yml`:

```yaml
project:
  type: website
  output-dir: _site
  resources:
    - index.html
```

This ensures the root `index.html` is copied to `_site/` during build.

**Step 2: Verify YAML syntax**

```bash
python3 -c "import yaml; yaml.safe_load(open('_quarto.yml'))"
```

**Step 3: Commit**

```bash
git add _quarto.yml
git commit -m "chore: configure root index.html as project resource"
```

---

## Task 12: Test Site Build

**Files:**

- None (verification only)

**Step 1: Run Quarto render**

```bash
quarto render
```

Expected: Build completes without errors.

**Step 2: Verify output structure**

```bash
ls -la _site/
ls -la _site/en/
ls -la _site/fr/
```

Expected:

- `_site/index.html` (redirect file)
- `_site/en/index.html`, `_site/en/about.html`, etc.
- `_site/fr/index.html`, `_site/fr/about.html`, etc.

**Step 3: Verify both language versions rendered**

```bash
ls _site/en/blog/posts/
ls _site/fr/blog/posts/
```

Expected: Both contain `2026-02-02-hello-world/` directory.

**Step 4: Test local preview (optional manual verification)**

```bash
quarto preview
```

Then manually test:

- Navigate to `http://localhost:XXXX/` - should redirect based on browser language
- Navigate to `http://localhost:XXXX/en/` - should show English homepage
- Navigate to `http://localhost:XXXX/fr/` - should show French homepage (content still English)
- Test navbar links work within each language

**Step 5: Commit any build-related fixes if needed**

If build revealed issues, fix and commit with descriptive message.

---

## Task 13: Final Verification and Commit

**Step 1: Run git status**

```bash
git status
```

Expected: Clean working directory (all changes committed).

**Step 2: Review commit history**

```bash
git log --oneline -10
```

Expected: Series of commits for each task.

**Step 3: Push branch**

```bash
git push -u origin feature/multilang-phase-1
```

---

## Exit Criteria

- [ ] `/en/` directory contains: `index.qmd`, `about.qmd`, `contact.qmd`, `thanks.qmd`, `_metadata.yml`, `blog/`
- [ ] `/fr/` directory contains identical structure to `/en/`
- [ ] `/en/_metadata.yml` contains `lang: en`
- [ ] `/fr/_metadata.yml` contains `lang: fr`
- [ ] Root `index.html` redirect exists and detects browser language
- [ ] `_quarto.yml` updated for subdirectory structure
- [ ] `quarto render` completes without errors
- [ ] `_site/en/` and `_site/fr/` both contain rendered HTML
- [ ] Original root-level `.qmd` files are removed (moved to `/en/`)
- [ ] All changes committed to `feature/multilang-phase-1` branch
- [ ] Branch pushed to origin

---

## Notes for Implementer

1. **Relative paths are key**: Quarto resolves navbar links relative to the current page. `blog/index.qmd` in navbar becomes `/en/blog/index.qmd` when on an `/en/` page.

2. **_metadata.yml inheritance**: Files in `en/_metadata.yml` apply to all `.qmd` files in `/en/` and subdirectories. Same for French.

3. **Shared resources stay at root**: `images/`, `_includes/`, `styles.css` remain at project root and are accessible from both language directories.

4. **Content is still English in /fr/**: This phase only sets up structure. Actual French translation happens in Phase 2.

5. **Build may show warnings**: Quarto may warn about duplicate content or missing translations. These are expected and will be resolved in later phases.
