# Phase 1 Plan Review

**Date:** 2026-02-04
**Reviewer:** Claude Code
**Plan Being Reviewed:** `/home/raph/Documents/sandbox/raphaelsimon.fr/.drafts/phase-1-plan.md`
**Macro Design Reference:** `/home/raph/Documents/sandbox/raphaelsimon.fr/.drafts/multilang-design-plan.md`

---

## Executive Summary

The Phase 1 plan is **well-structured and mostly correct**, with detailed step-by-step guidance that should execute successfully. However, there are **5 issues** identified (3 critical, 1 medium, 1 minor) that must be fixed before implementation. The plan correctly implements the Phase 1 requirements from the macro design plan, but needs adjustments to account for actual project state and Quarto configuration accuracy.

**Overall Assessment: NEEDS CHANGES**

---

## Detailed Findings

### 1. CRITICAL: Task 7 _quarto.yml Configuration Incorrect

**Issue:** The _quarto.yml shown in Task 7 (lines 261-316) does NOT match the actual current configuration. More importantly, it does NOT include the `lang: en` removal required by the design plan, nor does it include the `resources:` section added in Task 11.

**Current actual _quarto.yml (line 65):**
```yaml
# Default language
lang: en
```

**Task 7 shows (line 262-316):**
- No `lang:` field at root level (correct per design)
- Relative navbar paths like `blog/index.qmd` (correct)
- But this is an INCOMPLETE replacement that would lose other settings

**Task 11 adds (lines 462-470):**
```yaml
project:
  type: website
  output-dir: _site
  resources:
    - index.html
```

**Problem:** These two tasks manipulate the same file in sequence, but Task 7's replacement doesn't preserve all necessary content from Task 11. If implementer follows Task 7, then Task 11, the final file may be malformed.

**Severity:** CRITICAL

**Suggested Fix:**

Replace Task 7's instruction to show the COMPLETE updated _quarto.yml that will be used (including the resources section):

**OLD (lines 259-316):**
```
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
      - icon: envelope
        href: mailto:contact@raphaelsimon.fr
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
```

**NEW:**
```
Replace the existing `_quarto.yml` with:

```yaml
project:
  type: website
  output-dir: _site
  resources:
    - index.html

website:
  title: "Raphaël Simon"
  description: "Personal website - Medicine, Public Health, Software Engineering, Data Science"
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
        href: https://github.com/rplsmn
        aria-label: GitHub
      - icon: linkedin
        href: https://linkedin.com/in/raphael-simon-md
        aria-label: LinkedIn
      - icon: bluesky
        href: https://bsky.app/profile/raphsmn.bsky.social
        aria-label: Bluesky
      - icon: rss
        href: blog/index.xml
        aria-label: RSS Feed

  page-footer:
    left: |
      © 2026 Raphaël Simon
    right:
      - icon: github
        href: https://github.com/rplsmn
      - icon: envelope
        href: mailto:contact@raphaelsimon.fr

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

**Notes:**
- This now includes `resources: - index.html` from Task 11, eliminating the need for a separate Task 11 file edit
- Uses actual GitHub usernames from current _quarto.yml: `rplsmn`, `raphael-simon-md`, `raphsmn.bsky.social`
- Includes `description:` field from current config
- Removes `lang: en` from root (languages now in subdirectory `_metadata.yml`)
- Preserves all other settings
```

Then **DELETE Task 11** entirely, as it's now redundant and integrated into Task 7.

---

### 2. CRITICAL: Task 2 Misses Existing Root Files

**Issue:** Task 2 only moves 4 files (`index.qmd`, `about.qmd`, `contact.qmd`, `thanks.qmd`) but doesn't account for other root-level files that may exist and need to be moved or accounted for (e.g., `blog/_metadata.yml` is mentioned in Task 3, but the plan doesn't list all files comprehensively).

**Current actual project structure shows:**
```
./contact.qmd
./index.qmd
./thanks.qmd
./about.qmd
./blog/index.qmd
./blog/_metadata.yml
```

**Severity:** CRITICAL (will leave orphaned files at root)

**Suggested Fix:**

Update Task 2 description and verify step to be more comprehensive. Add a Pre-Task 2 verification step:

**Insert NEW step before Task 2:**

```markdown
## Task 1.5: Audit Current Root Files

**Step 1: List all root-level .qmd and configuration files**

```bash
ls -la *.qmd *.yml *.yaml *.html 2>/dev/null | grep -E "\.(qmd|yml|yaml|html)$"
```

**Expected output:** Should show at minimum:
- `index.qmd`
- `about.qmd`
- `contact.qmd`
- `thanks.qmd`
- Any other `.qmd` files that aren't in `blog/`

**Step 2: Verify blog directory exists**

```bash
ls -la blog/
```

**Expected output:** Should show:
- `index.qmd`
- `_metadata.yml`
- `posts/` directory (or similar)

**Purpose:** This ensures you catch all root files before moving them.
```

Then update Task 2 Step 1's bash comment:

**OLD (line 64):**
```bash
git mv index.qmd en/index.qmd
git mv about.qmd en/about.qmd
git mv contact.qmd en/contact.qmd
git mv thanks.qmd en/thanks.qmd
```

**NEW:**
```bash
# Move all root-level .qmd content files to /en/
# Note: This assumes only the 4 main pages at root. If your audit found others, move those too.
git mv index.qmd en/index.qmd
git mv about.qmd en/about.qmd
git mv contact.qmd en/contact.qmd
git mv thanks.qmd en/thanks.qmd
```

---

### 3. CRITICAL: Task 3 Blog Move Logic Has Edge Case

**Issue:** Task 3 Step 2 (line 103) uses `git mv blog/posts/2026-02-02-hello-world en/blog/posts/` but this assumes the post directory exists. The command will fail if there are multiple post directories or if the directory name differs.

**Current project has:** `blog/posts/2026-02-02-hello-world/` (confirmed by files list)

**Severity:** CRITICAL (command will fail if no posts exist OR if post slug differs from what's hardcoded)

**Suggested Fix:**

Update Task 3 Step 2 and add verification:

**OLD (lines 100-104):**
```
**Step 2: Move blog posts directory**

```bash
git mv blog/posts/2026-02-02-hello-world en/blog/posts/
```
```

**NEW:**
```
**Step 2: Move blog posts directories**

First, identify what posts exist:

```bash
ls -la blog/posts/
```

Then move ALL posts (not just one specific one):

```bash
# Move all post directories at once
git mv blog/posts/* en/blog/posts/
```

If `blog/posts/` is empty (no posts yet), this command will warn but won't fail — that's OK.
```

---

### 4. MEDIUM: Task 4 Verification Command May Fail or Be Unclear

**Issue:** Task 4 Step 2 uses `diff <(ls -R en/) <(ls -R fr/)` (line 156). This process substitution syntax works in bash but:
1. May not work in all shells
2. Output shows directory listings, not file content — structure could match but file content could differ
3. Minor: the check is superficial

**Severity:** MEDIUM (non-portable, but won't stop implementation)

**Suggested Fix:**

**OLD (lines 155-159):**
```
**Step 2: Verify French structure matches English**

```bash
diff <(ls -R en/) <(ls -R fr/)
```

Expected: No output (structures are identical).
```

**NEW:**
```
**Step 2: Verify French structure matches English**

Use a more portable verification:

```bash
# Compare directory trees (requires tree command, or use find as fallback)
if command -v tree &> /dev/null; then
  tree en/ > /tmp/en.tree
  tree fr/ > /tmp/fr.tree
  diff /tmp/en.tree /tmp/fr.tree
else
  # Fallback: just verify key directories exist
  for dir in index blog blog/posts; do
    [ -f "en/$dir.qmd" ] || [ -d "en/$dir" ] && echo "en/$dir OK" || echo "MISSING: en/$dir"
    [ -f "fr/$dir.qmd" ] || [ -d "fr/$dir" ] && echo "fr/$dir OK" || echo "MISSING: fr/$dir"
  done
fi
```

Expected: No errors, or output confirming all directories exist in both languages.
```

---

### 5. MINOR: Task 8 & 9 Are Vague About What Links Need Fixing

**Issue:** Task 8 and 9 (lines 341-405) say "read the file" and look for links, but don't provide clear examples of what to look for or what the actual links are in the current files.

**Severity:** MINOR (implementer must read files anyway, but the plan could be clearer)

**Suggested Fix:**

**Insert before Task 8 Step 1 (after line 340):**

```markdown
**Context:** After moving content to language subdirectories, internal links need to stay relative. For example:
- `[Contact](contact.qmd)` in `en/about.qmd` is fine — it resolves to `en/contact.qmd`
- `[Home](/index.qmd)` in `en/thanks.qmd` is broken — absolute paths don't work. Should be `[Home](index.qmd)` or `[Home](/)`
- Blog listing in `en/index.qmd` that references `blog/posts` is fine — resolves to `en/blog/posts`

The key rule: **Use relative paths or bare paths** (no leading `/` in internal links).
```

---

## Consistency with Macro Design Plan

**CHECK:** Does Phase 1 plan correctly implement the "Phase 1: Structure" section from multilang-design-plan.md (lines 288-297)?

| Design Requirement | Phase 1 Plan Coverage | Status |
|-------------------|----------------------|--------|
| Create `/en/` and `/fr/` directories | Task 1 ✓ | ✓ |
| Copy existing files to `/en/` | Task 2-4 ✓ | ✓ |
| Duplicate structure to `/fr/` with same filenames | Task 4 ✓ | ✓ |
| Move `blog/posts/` to `/en/blog/posts/` | Task 3 ✓ (with caveat) | ~ (needs fix) |
| Set up root `index.html` redirect | Task 10 ✓ | ✓ |
| Create `_metadata.yml` for each language | Tasks 5-6 ✓ | ✓ |
| Update `_quarto.yml` | Task 7 ✓ (with caveat) | ~ (needs fix) |
| Keep shared resources at root | Not explicitly stated | ✓ (implicit) |
| Verify build and both `/en/` and `/fr/` render | Task 12 ✓ | ✓ |

**Conclusion:** Phase 1 plan correctly maps to design requirements, but issues above must be fixed.

---

## Issues Summary Table

| # | Task | Severity | Type | Summary |
|---|------|----------|------|---------|
| 1 | 7 | CRITICAL | Configuration | _quarto.yml incomplete; doesn't integrate Task 11 properly |
| 2 | 2 | CRITICAL | Completeness | Doesn't audit all root files; may leave orphans |
| 3 | 3 | CRITICAL | Correctness | Hardcoded post directory name; fails if posts differ |
| 4 | 4 | MEDIUM | Portability | diff syntax non-portable; verification is superficial |
| 5 | 8-9 | MINOR | Clarity | Links to fix aren't shown explicitly |

---

## Test Plan Observations

Task 12 (lines 489-540) is well-designed with good verification steps. Additions:

**After Task 12 Step 3, add:**

```bash
**Step 3.5: Verify no 404s in output**

```bash
# Check that blog posts actually exist in output
find _site/en/blog/posts/ _site/fr/blog/posts/ -name "index.html" 2>/dev/null | wc -l
```

Expected: At least 1 file in each language's posts directory (the hello-world post).
```

---

## Detailed Change Recommendations

### Change 1: Consolidate _quarto.yml Updates

**What:** Merge Task 7 and Task 11 into one coherent update.

**Where:** Lines 240-485 (Task 7 and Task 11)

**Action:**
- Keep Task 7 as the single _quarto.yml update
- Update Task 7's YAML to include `resources: - index.html`
- Use actual GitHub URLs from current config
- Delete Task 11 entirely
- Renumber remaining tasks (Task 12 becomes Task 11, etc.)

---

### Change 2: Add Pre-audit Step

**What:** Verify all root files before moving them.

**Where:** Insert before Task 2 (between line 52-84)

**Action:** Add "Task 1.5: Audit Current Root Files" with bash commands to list and verify all root-level files.

---

### Change 3: Fix Blog Move Command

**What:** Make blog post move more robust.

**Where:** Task 3, Step 2 (lines 100-104)

**Action:** Replace hardcoded post directory name with `blog/posts/*` to move all posts, not just one.

---

### Change 4: Improve Structure Verification

**What:** Use portable verification for French/English structure match.

**Where:** Task 4, Step 2 (lines 155-159)

**Action:** Replace `diff <(ls -R)` with either `tree` command or explicit directory checks.

---

### Change 5: Add Link Fixing Context

**What:** Clarify what links need fixing and why.

**Where:** Before Task 8, Step 1 (before line 348)

**Action:** Add context section explaining relative path rules for internal links.

---

## Implementation Order Notes

1. Fix Issues #1, #2, #3 before implementation — these are blockers
2. Issue #4 (medium) — should fix, won't break implementation
3. Issue #5 (minor) — improve clarity, won't affect success

---

## Questions for Author

1. **Are there other root-level .qmd files beyond the 4 main pages?** (Contact/About/Thanks/Index)
2. **Will there always be blog posts in `blog/posts/`, or might it be empty initially?**
3. **Is the hardcoded GitHub username `rplsmn` still correct, or should it match the header in _quarto.yml?** (Currently shows both `raphaelsimon` and `rplsmn` in different places)

---

## Final Assessment

**NEEDS CHANGES** — Fix the 3 critical issues (Tasks 7, 2, 3) and optionally the medium/minor issues. Once fixed, this is a solid, detailed implementation plan that should execute cleanly.

The plan demonstrates:
- ✓ Clear task sequencing with dependencies respected
- ✓ Detailed verification steps at each stage
- ✓ Proper git workflow
- ✓ Good attention to Quarto configuration
- ✓ Comprehensive exit criteria

After fixes:
- ✓ Ready for implementation review
- ✓ Low risk of failure
- ✓ Will correctly implement Phase 1 of the multilingual site redesign
