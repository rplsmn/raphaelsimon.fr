# Phase 1 Implementation Plan: Structure

**Date:** 2026-02-04  
**Phase:** 1 of 5 (Structure)  
**Status:** Ready for execution

---

## Context & Goal

Transform the current single-language Quarto website into a multilingual structure with `/en/` and `/fr/` subdirectories. This phase focuses entirely on directory restructuring and configuration — no content translation occurs. Both language versions will contain identical English content initially; translation happens in Phase 2.

**Success Definition:** Site builds successfully with both `/en/` and `/fr/` routes accessible. Root domain redirects to appropriate language. All existing blog posts and pages render correctly in their new locations.

---

## Prerequisites

Verify the following tools are available before starting:

```bash
# Quarto (minimum version 1.3)
quarto --version

# Git (for safety commits)
git --version

# Python 3 (for future manifest script — verify but not used in Phase 1)
python3 --version
```

**Expected state:**
- Current site structure has root-level `.qmd` files (index, about, contact, thanks)
- Blog posts exist in `/blog/posts/` at project root
- `_quarto.yml` references root-level content directly

---

## Safety & Rollback

**Before starting:**
1. Commit all current changes: `git add -A && git commit -m "Pre-Phase1: Checkpoint before multilang restructure"`
2. Create a safety branch: `git branch pre-multilang-backup`

**To rollback if build breaks:**
```bash
git reset --hard pre-multilang-backup
git branch -D multilang-phase1  # If you created a working branch
```

**Quick build verification command:**
```bash
quarto render && echo "✓ Build successful" || echo "✗ Build failed"
```

---

## Task Checklist

### Task 1: Create language directory structure

**Action:** Create `/en/` and `/fr/` directories with blog subdirectories.

**Commands:**
```bash
mkdir -p en/blog/posts
mkdir -p fr/blog/posts
```

**Files touched:**
- `en/` (new directory)
- `fr/` (new directory)
- `en/blog/posts/` (new directory)
- `fr/blog/posts/` (new directory)

**Success criteria:**
- `ls -d en fr en/blog/posts fr/blog/posts` shows all four paths exist
- Directories are empty (verified with `find en fr -type f`)

---

### Task 2: Copy root content files to `/en/`

**Action:** Copy homepage, about, contact, and thanks pages into English directory.

**Commands:**
```bash
cp index.qmd en/index.qmd
cp about.qmd en/about.qmd
cp contact.qmd en/contact.qmd
cp thanks.qmd en/thanks.qmd
```

**Files touched:**
- `en/index.qmd` (new)
- `en/about.qmd` (new)
- `en/contact.qmd` (new)
- `en/thanks.qmd` (new)

**Success criteria:**
- `ls en/*.qmd` shows all four files
- `diff index.qmd en/index.qmd` shows no differences (identical content)
- All files have valid YAML frontmatter (run `quarto inspect en/index.qmd`)

---

### Task 3: Copy blog index to `/en/blog/`

**Action:** Copy blog listing page to English blog directory.

**Commands:**
```bash
cp blog/index.qmd en/blog/index.qmd
```

**Files touched:**
- `en/blog/index.qmd` (new)

**Success criteria:**
- `test -f en/blog/index.qmd` returns success
- `diff blog/index.qmd en/blog/index.qmd` shows no differences

---

### Task 4: Move blog posts to `/en/blog/posts/`

**Action:** Move existing blog posts from root `/blog/posts/` to `/en/blog/posts/`.

**Commands:**
```bash
# Move all blog post directories
mv blog/posts/* en/blog/posts/ 2>/dev/null || true
# Verify blog/posts is now empty
ls -A blog/posts/
```

**Files touched:**
- All subdirectories under `blog/posts/*` (moved to `en/blog/posts/`)

**Success criteria:**
- `blog/posts/` directory is empty or contains only `.gitkeep` (verify with `ls -A blog/posts/`)
- `ls en/blog/posts/` shows all post directories
- At least one post index exists: `test -f en/blog/posts/*/index.qmd` returns success

---

### Task 5: Copy blog metadata to `/en/blog/`

**Action:** Copy blog-level metadata file if it exists.

**Commands:**
```bash
# Check if metadata exists and copy if present
if [ -f blog/_metadata.yml ]; then
  cp blog/_metadata.yml en/blog/_metadata.yml
  echo "✓ Blog metadata copied"
else
  echo "ℹ No blog metadata file found (OK)"
fi
```

**Note:** This metadata file is optional and only needed if blog-level settings exist in the current site.

**Files touched:**
- `en/blog/_metadata.yml` (new, conditional)

**Success criteria:**
- If `blog/_metadata.yml` exists, `en/blog/_metadata.yml` exists with identical content
- Command completes without errors

---

### Task 6: Duplicate entire `/en/` structure to `/fr/`

**Action:** Create identical French directory structure (content still in English — translation is Phase 2).

**Commands:**
```bash
# Copy all .qmd files from en/ to fr/
cp en/index.qmd fr/index.qmd
cp en/about.qmd fr/about.qmd
cp en/contact.qmd fr/contact.qmd
cp en/thanks.qmd fr/thanks.qmd
cp en/blog/index.qmd fr/blog/index.qmd

# Copy blog metadata if it exists
if [ -f en/blog/_metadata.yml ]; then
  cp en/blog/_metadata.yml fr/blog/_metadata.yml
fi
```

**Files touched:**
- `fr/index.qmd` (new)
- `fr/about.qmd` (new)
- `fr/contact.qmd` (new)
- `fr/thanks.qmd` (new)
- `fr/blog/index.qmd` (new)
- `fr/blog/_metadata.yml` (new, conditional)

**Success criteria:**
- `diff -r en/ fr/ --exclude=posts` shows no differences (fr/ is exact copy except posts directory)
- `ls fr/*.qmd` shows all four root pages
- `test -f fr/blog/index.qmd` returns success
- `fr/blog/posts/` remains empty (verified with `ls -A fr/blog/posts/`)

---

### Task 7: Create language-specific `_metadata.yml` files

**Action:** Create metadata files that set the `lang` attribute for each language directory.

**Commands:**
```bash
# Create English metadata
cat > en/_metadata.yml << 'EOF'
lang: en
author: "Raphaël Simon"
EOF

# Create French metadata
cat > fr/_metadata.yml << 'EOF'
lang: fr
author: "Raphaël Simon"
EOF
```

**Files touched:**
- `en/_metadata.yml` (new)
- `fr/_metadata.yml` (new)

**Success criteria:**
- Both files exist: `test -f en/_metadata.yml && test -f fr/_metadata.yml`
- English metadata contains `lang: en` (verify: `grep "lang: en" en/_metadata.yml`)
- French metadata contains `lang: fr` (verify: `grep "lang: fr" fr/_metadata.yml`)
- Both contain `author:` field (verify: `grep "author:" {en,fr}/_metadata.yml`)

---

### Task 8: Update `_quarto.yml` for multilingual structure

**Action:** Modify Quarto config to render from language subdirectories instead of root. Remove root-level page references, update navbar links to point to `/en/` paths (default language).

**Commands:**
```bash
# Backup original config
cp _quarto.yml _quarto.yml.backup
```

**Manual edit to `_quarto.yml`:**

1. Remove the root-level `lang: en` line (now set per-language via `_metadata.yml`)

2. Update `website.navbar.left` section:
   ```yaml
   navbar:
     background: dark
     left:
       - text: Blog
         href: en/blog/index.qmd
       - text: About
         href: en/about.qmd
       - text: Contact
         href: en/contact.qmd
   ```

3. Update RSS link in `website.navbar.right`:
   ```yaml
   - icon: rss
     href: en/blog/index.xml
     aria-label: RSS Feed
   ```

4. Update `website.site-url` if it points to root pages (should remain `https://raphaelsimon.fr`)

5. **Add project rendering configuration:**
   ```yaml
   project:
     type: website
     output-dir: _site
     render:
       - en/
       - fr/
       - index.html
   ```

**Files touched:**
- `_quarto.yml` (modified)
- `_quarto.yml.backup` (new)

**Success criteria:**
- Navbar links point to `en/` paths: `grep "href: en/" _quarto.yml | wc -l` returns at least 3
- No root-level `lang: en` line exists outside project metadata: `grep -v "^#" _quarto.yml | grep "^lang:" | wc -l` returns 0
- `project.render` includes both `en/` and `fr/`: `grep "render:" _quarto.yml -A 3`
- Config is valid YAML: `quarto inspect _quarto.yml` runs without error

---

### Task 9: Create root `index.html` redirect

**Action:** Create language-detecting redirect at site root that directs to `/fr/` or `/en/` based on browser language.

**Commands:**
```bash
cat > index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Redirecting...</title>
  <meta name="robots" content="noindex, nofollow">
  <script>
    // Detect browser language preference
    const lang = navigator.language?.startsWith('fr') ? 'fr' : 'en';
    window.location.replace('/' + lang + '/');
  </script>
  <noscript>
    <!-- Fallback for users with JavaScript disabled -->
    <meta http-equiv="refresh" content="0;url=/en/" />
  </noscript>
</head>
<body>
  <p>Redirecting to language-specific homepage...</p>
  <p>If not redirected automatically, please choose:</p>
  <ul>
    <li><a href="/en/">English</a></li>
    <li><a href="/fr/">Français</a></li>
  </ul>
</body>
</html>
EOF
```

**Files touched:**
- `index.html` (new, replaces `index.qmd` in root)

**Success criteria:**
- `test -f index.html` returns success
- File contains language detection JavaScript: `grep "navigator.language" index.html`
- File contains noscript fallback: `grep "noscript" index.html`
- File contains manual links to both languages: `grep 'href="/en/"' index.html && grep 'href="/fr/"' index.html`

---

### Task 10: Clean up root-level `.qmd` files

**Action:** Remove original root-level content files now that they've been copied into language directories.

**Commands:**
```bash
# Safety check: verify posts were moved before deleting blog/
if [ -d blog/posts ] && [ -z "$(find blog/posts -type f 2>/dev/null)" ]; then
  # Remove original root pages (already copied to en/ and fr/)
  rm -f index.qmd about.qmd contact.qmd thanks.qmd
  
  # Remove now-empty blog/ directory structure
  rm -rf blog/
  echo "✓ Cleanup complete"
else
  echo "⚠ blog/posts/ not empty or missing — skipping deletion as safety measure"
  exit 1
fi
```

**Files touched:**
- `index.qmd` (deleted)
- `about.qmd` (deleted)
- `contact.qmd` (deleted)
- `thanks.qmd` (deleted)
- `blog/` (deleted, entire directory)

**Success criteria:**
- Root directory has no `.qmd` files except in subdirectories: `ls *.qmd 2>&1 | grep "No such file"`
- `blog/` directory no longer exists: `test ! -d blog/`
- `en/` and `fr/` directories still contain all content: `ls en/*.qmd fr/*.qmd en/blog/posts/`

---

### Task 11: Verify shared assets remain at root

**Action:** Confirm that shared resources (styles, images, includes, extensions) are still in project root and accessible to both languages.

**Commands:**
```bash
# List expected shared directories/files
ls -d styles.css images/ _includes/ _extensions/ 2>/dev/null || echo "Some expected assets missing"

# Verify no .qmd files leaked into shared directories
find styles.css images/ _includes/ _extensions/ -name "*.qmd" 2>/dev/null && echo "⚠ Unexpected .qmd in shared assets" || echo "✓ No .qmd in shared assets"
```

**Files touched:**
- None (verification only)

**Success criteria:**
- `styles.css` exists at root: `test -f styles.css`
- `images/` directory exists: `test -d images/`
- `_includes/` exists if used: `test -d _includes/ || echo "Not used (OK)"`
- `_extensions/` exists if used: `test -d _extensions/ || echo "Not used yet (OK for Phase 1)"`
- No `.qmd` files in shared asset directories

---

### Task 12: First build test

**Action:** Attempt to build the site and verify both language versions render.

**Commands:**
```bash
# Clean any previous build artifacts
rm -rf _site/

# Render the site
quarto render

# Check for build errors or warnings
if quarto render 2>&1 | grep -qi "error"; then
  echo "✗ Build errors detected"
  exit 1
fi

# Verify build output
echo "=== Build verification ==="
test -d _site/en && echo "✓ /en/ built" || echo "✗ /en/ missing"
test -d _site/fr && echo "✓ /fr/ built" || echo "✗ /fr/ missing"
test -f _site/index.html && echo "✓ Root redirect exists" || echo "✗ Root redirect missing"
test -f _site/en/index.html && echo "✓ English homepage built" || echo "✗ English homepage missing"
test -f _site/fr/index.html && echo "✓ French homepage built" || echo "✗ French homepage missing"
```

**Files touched:**
- `_site/` (generated, not tracked)

**Success criteria:**
- `quarto render` completes without errors (exit code 0)
- No build errors or warnings in output
- `_site/en/` directory exists with all pages
- `_site/fr/` directory exists with all pages
- `_site/index.html` exists (redirect page)
- `_site/en/blog/posts/` contains built blog posts
- `_site/fr/blog/posts/` is empty (no posts in French yet)

---

### Task 13: Verify English content renders correctly

**Action:** Check that English pages are accessible and contain expected content.

**Commands:**
```bash
# Check English homepage exists and has content
test -f _site/en/index.html && grep -q "Raphaël Simon" _site/en/index.html && echo "✓ EN homepage OK" || echo "✗ EN homepage issue"

# Check English about page
test -f _site/en/about.html && echo "✓ EN about page built" || echo "✗ EN about page missing"

# Check English blog listing
test -f _site/en/blog/index.html && echo "✓ EN blog listing built" || echo "✗ EN blog listing missing"

# Verify at least one blog post built
find _site/en/blog/posts/ -name "index.html" | head -n 1 | xargs test -f && echo "✓ EN blog posts built" || echo "✗ No EN blog posts"

# Check language tag in English pages
grep -q 'lang="en"' _site/en/index.html && echo "✓ EN language tag correct" || echo "✗ EN language tag missing/wrong"
```

**Files touched:**
- None (verification only)

**Success criteria:**
- All English pages build successfully
- HTML files contain `lang="en"` attribute
- Blog posts are accessible under `/en/blog/posts/`
- Content matches original site (text unchanged)

---

### Task 14: Verify French structure renders correctly

**Action:** Check that French pages build with correct language tags (content will be English — expected in Phase 1).

**Commands:**
```bash
# Check French homepage exists
test -f _site/fr/index.html && grep -q "Raphaël Simon" _site/fr/index.html && echo "✓ FR homepage OK" || echo "✗ FR homepage issue"

# Check French about page
test -f _site/fr/about.html && echo "✓ FR about page built" || echo "✗ FR about page missing"

# Check French blog listing
test -f _site/fr/blog/index.html && echo "✓ FR blog listing built" || echo "✗ FR blog listing missing"

# Verify French blog posts directory is empty (no translations yet)
[ -z "$(find _site/fr/blog/posts/ -name 'index.html' 2>/dev/null)" ] && echo "✓ FR blog posts empty (expected)" || echo "⚠ FR has posts (unexpected in Phase 1)"

# Check language tag in French pages
grep -q 'lang="fr"' _site/fr/index.html && echo "✓ FR language tag correct" || echo "✗ FR language tag missing/wrong"
```

**Files touched:**
- None (verification only)

**Success criteria:**
- All French pages build successfully
- HTML files contain `lang="fr"` attribute
- Content is identical to English (translation deferred to Phase 2)
- French blog listing shows "no posts" or empty state
- Quarto UI strings (e.g., search placeholder, TOC title) render in French automatically

---

### Task 15: Verify root redirect functionality

**Action:** Confirm root `index.html` redirect contains correct JavaScript and fallback logic.

**Commands:**
```bash
# Verify redirect file wasn't overwritten by Quarto
test -f _site/index.html && echo "✓ Root redirect preserved" || echo "✗ Root redirect missing"

# Check JavaScript redirect logic exists
grep -q "navigator.language" _site/index.html && echo "✓ JS language detection present" || echo "✗ JS redirect missing"

# Check noscript fallback
grep -q "<noscript>" _site/index.html && echo "✓ Noscript fallback present" || echo "✗ Noscript missing"

# Check manual links as final fallback
grep -q 'href="/en/"' _site/index.html && grep -q 'href="/fr/"' _site/index.html && echo "✓ Manual links present" || echo "✗ Manual links missing"
```

**Files touched:**
- None (verification only)

**Success criteria:**
- `_site/index.html` exists and is NOT a Quarto-generated page
- File contains JavaScript language detection
- Noscript meta refresh points to `/en/` (English fallback)
- Manual links to both `/en/` and `/fr/` are present

---

### Task 16: Test site with local preview

**Action:** Start Quarto preview server and manually verify routes work.

**Commands:**
```bash
# Start preview server (will run in foreground)
quarto preview --no-browser --port 4444

# In another terminal, test routes:
curl -s http://localhost:4444/ | grep -q "Redirecting" && echo "✓ Root redirect serves"
curl -s http://localhost:4444/en/ | grep -q 'lang="en"' && echo "✓ /en/ route works"
curl -s http://localhost:4444/fr/ | grep -q 'lang="fr"' && echo "✓ /fr/ route works"
```

**Files touched:**
- None (runtime verification only)

**Success criteria:**
- Preview server starts without errors
- `http://localhost:4444/` serves redirect page
- `http://localhost:4444/en/` serves English homepage with `lang="en"`
- `http://localhost:4444/fr/` serves French homepage with `lang="fr"`
- Navigation between pages works (click "About", "Blog", etc.)
- Search function is accessible (keyboard shortcut `/` works)

**Note:** Stop preview server with Ctrl+C when verification complete.

---

### Task 17: Final safety commit

**Action:** Commit all Phase 1 changes as a checkpoint before moving to Phase 2.

**Commands:**
```bash
# Stage all changes
git add -A

# Commit with descriptive message
git commit -m "Phase 1: Multilingual structure

- Created /en/ and /fr/ language directories
- Moved all content into language subdirectories
- Added per-language _metadata.yml with lang: en/fr
- Updated _quarto.yml to render from language directories
- Created root index.html redirect (JS + noscript fallback)
- Verified build success: both languages render correctly
- Content is English in both (translation deferred to Phase 2)

Build status: ✓ Passing
Routes verified: / → redirect, /en/ → works, /fr/ → works"

# Tag the commit for easy reference
git tag phase-1-complete

echo "✓ Phase 1 committed and tagged"
```

**Files touched:**
- `.git/` (commit and tag)

**Success criteria:**
- `git status` shows working tree clean
- `git log -1` shows Phase 1 commit message
- `git tag` includes `phase-1-complete`
- `git diff HEAD~1 --stat` shows expected file changes (additions in `en/`, `fr/`, modifications to `_quarto.yml`, deletions at root)

---

## Validation Summary

After completing all tasks, verify these conditions:

### Directory Structure
```
raphaelsimon.fr/
├── _quarto.yml           # Updated: renders en/ and fr/
├── index.html            # New: language redirect
├── styles.css            # Unchanged: shared asset
├── images/               # Unchanged: shared asset
├── en/
│   ├── _metadata.yml     # New: lang: en
│   ├── index.qmd
│   ├── about.qmd
│   ├── contact.qmd
│   ├── thanks.qmd
│   └── blog/
│       ├── index.qmd
│       └── posts/
│           └── [existing posts moved here]
└── fr/
    ├── _metadata.yml     # New: lang: fr
    ├── index.qmd
    ├── about.qmd
    ├── contact.qmd
    ├── thanks.qmd
    └── blog/
        ├── index.qmd
        └── posts/        # Empty (expected)
```

### Build Output
```
_site/
├── index.html            # Redirect to /en/ or /fr/
├── en/
│   ├── index.html        # lang="en"
│   ├── about.html
│   ├── contact.html
│   ├── thanks.html
│   └── blog/
│       ├── index.html
│       ├── index.xml     # RSS feed for EN
│       └── posts/
│           └── [built posts]
└── fr/
    ├── index.html        # lang="fr"
    ├── about.html
    ├── contact.html
    ├── thanks.html
    └── blog/
        ├── index.html
        ├── index.xml     # RSS feed for FR (empty)
        └── posts/        # Empty (expected)
```

### Final Checks
```bash
# All must pass:
quarto render                                           # Exit code 0
test -f _site/index.html                                # Root redirect exists
test -d _site/en && test -d _site/fr                    # Both languages built
grep -q 'lang="en"' _site/en/index.html                 # English lang tag
grep -q 'lang="fr"' _site/fr/index.html                 # French lang tag
find _site/en/blog/posts/ -name "*.html" | wc -l       # > 0 (posts exist)
find _site/fr/blog/posts/ -name "*.html" | wc -l       # = 0 (no FR posts yet)
curl -s http://localhost:4444/en/ | head -n 5          # Preview works
```

---

## Next Steps (Not Part of Phase 1)

Phase 1 is complete when:
- ✅ Site builds without errors
- ✅ Both `/en/` and `/fr/` routes are accessible
- ✅ Root redirect works (manual browser test confirms language detection)
- ✅ All English content renders correctly under `/en/`
- ✅ French pages render with `lang="fr"` (content still English)
- ✅ Changes are committed with `phase-1-complete` tag

**Phase 2 will handle:**
- French content translation for static pages
- French blog post translations or stubs
- Verification of Quarto's built-in French UI strings

**Do not proceed to Phase 2 until all validation checks pass.**
