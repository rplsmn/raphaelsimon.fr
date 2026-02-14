# Phase 6: Navbar Language Context Fix — Critical Review & Plan

**Date:** 2026-02-14
**Status:** Draft — awaiting approval
**Triggered by:** Mobile testing: selecting French, then clicking "Blog" navigates to English blog

---

## Critical Review of Phase 1–5 Implementation

### What Works Well

1. **Directory structure** — Symmetric `/en/` and `/fr/` trees, clean content separation
2. **Content translation** — All static pages translated, blog post scaffolding in place
3. **Language switcher UI** — The `ENG | FRA` toggle renders correctly, detects current language from URL
4. **SEO/hreflang** — Properly generated for all pages, x-default set to English
5. **Translation banner** — Machine-translated posts get flagged correctly
6. **Search** — Global index with language flags on results
7. **Root redirect** — Respects localStorage preference, falls back to browser language

### The Fundamental Architectural Weakness

**Quarto has no concept of per-language navigation.** The `_quarto.yml` navbar config is site-global:

```yaml
navbar:
  left:
    - text: Blog
      href: en/blog/index.qmd    # ← hardcoded to English
    - text: About
      href: en/about.qmd         # ← hardcoded to English
    - text: Contact
      href: en/contact.qmd       # ← hardcoded to English
```

This means **every rendered page** — whether under `/en/` or `/fr/` — gets navbar links pointing to `/en/` paths (relativized by Quarto to `../en/...`, `../../en/...`, `../../../../en/...` depending on directory depth).

The commit `bb44fc7` ("Fix navigation to maintain language context across pages") attempted to solve this with client-side JS that rewrites navbar hrefs at `DOMContentLoaded`. The approach is sound in principle but the implementation has a critical regex bug.

---

## Root Cause Analysis

### The Bug

In `_includes/navbar-lang-switch.html`, line 16:

```javascript
var match = href.match(/^(\.\.\/|\/)(en|fr)\/(.*)/);
```

This regex captures **exactly one** `../` or a single `/`. But Quarto generates relative paths whose depth varies by page location:

| Page | Navbar href to Blog | Regex matches? |
|------|-------------------|----------------|
| `/fr/index.html` | `../en/blog/index.html` | **Yes** (one `../`) |
| `/fr/about.html` | `../en/about.html` | **Yes** (one `../`) |
| `/fr/blog/index.html` | `../../en/blog/index.html` | **No** (two `../`) |
| `/fr/blog/posts/.../index.html` | `../../../../en/blog/index.html` | **No** (four `../`) |

**Result:** On any page deeper than 1 level under a language directory, navbar links are NOT rewritten. Clicking "Blog" from `/fr/blog/` sends you to `/en/blog/`.

### The Brand Link Has the Same Bug

Line 27:
```javascript
var brandMatch = brandHref.match(/^(\.\.\/|\/)?index\.html$/);
```

This matches `index.html` or `../index.html` but not `../../index.html` or deeper. On blog post pages, clicking the site title doesn't redirect to the correct language homepage.

### Why It Appears "Mobile Only"

It's not truly mobile-only — it fails on desktop too for pages at depth ≥ 2. But on the `/fr/` homepage (depth 1), the regex works, so a quick test on desktop from the homepage looks fine. The user's mobile test path was: landing page → choose French → click Blog → lands on English. This traverses from `/fr/` (depth 1, regex works) to the blog link that was correctly rewritten, but the **blog page itself** (`/fr/blog/index.html`, depth 2) then has broken navbar links pointing back to `/en/`.

---

## Proposed Fix

### Approach: Resolve to Absolute Paths via Browser URL API

Rather than trying to match arbitrary depths of `../`, let the browser resolve relative URLs to absolute ones, then swap the language prefix:

```javascript
// Rewrite navbar links to match current language
var navLinks = document.querySelectorAll('.navbar a.nav-link');
navLinks.forEach(function(link) {
  var href = link.getAttribute('href');
  if (!href || href.startsWith('http')) return;
  // Let the browser resolve the relative path to absolute
  var resolved = new URL(href, window.location.href).pathname;
  var match = resolved.match(/^\/(en|fr)\/(.*)/);
  if (match && match[1] !== currentLang) {
    link.setAttribute('href', '/' + currentLang + '/' + match[2]);
  }
});

// Fix brand link
var brandLink = document.querySelector('.navbar-brand');
if (brandLink) {
  var brandHref = brandLink.getAttribute('href');
  if (brandHref && !brandHref.startsWith('http')) {
    var resolved = new URL(brandHref, window.location.href).pathname;
    if (resolved === '/index.html' || resolved === '/') {
      brandLink.setAttribute('href', '/' + currentLang + '/');
    } else {
      var match = resolved.match(/^\/(en|fr)\/(.*)/);
      if (match && match[1] !== currentLang) {
        brandLink.setAttribute('href', '/' + currentLang + '/' + match[2]);
      }
    }
  }
}
```

**Why this is better than fixing the regex:**
- `new URL(href, base)` is a browser-native API that correctly resolves any relative path (`../`, `../../`, `./`, etc.) to an absolute path
- No regex for relative path prefixes — one fewer thing that can break
- Works at any directory depth, now and in the future
- `URL` API is supported in all modern browsers (IE11 excluded, which is irrelevant for this site)

### Changes Required

**Single file change:** `_includes/navbar-lang-switch.html`

1. Replace the nav link rewriting block (lines 10–20) with URL-resolution approach
2. Replace the brand link rewriting block (lines 22–32) with URL-resolution approach
3. No other files need changes

### Testing Checklist

After the fix, verify these pages have correctly rewritten navbar links:

- [ ] `/fr/` — navbar links → `/fr/blog/...`, `/fr/about.html`, `/fr/contact.html`
- [ ] `/fr/about.html` — same
- [ ] `/fr/blog/index.html` — same (this is the page that was broken)
- [ ] `/fr/blog/posts/2026-02-02-hello-world/index.html` — same
- [ ] `/en/` — navbar links stay pointing to `/en/` (no rewriting needed)
- [ ] Brand link (site title) → `/{currentLang}/` from any depth
- [ ] Language switcher `ENG | FRA` toggle still works
- [ ] localStorage persistence: choose FR, leave, come back → still FR

---

## Hugo Opportunity Cost Analysis

### The Question

Is the ongoing cost of working around Quarto's multilingual limitations high enough to justify migrating to Hugo, which handles multilingual natively?

### What Hugo Gives You

- **Per-language menus** defined in config — no JS rewriting needed
- **`.Page.AllTranslations`** template function — native language switcher in templates
- **Directory or filename-based** content organization for translations
- **Massive theme ecosystem** — many production-tested multilingual themes
- **Fast builds** — sub-second for small sites

### What Hugo Costs You

- **Migration effort**: 4–8 hours minimum (convert .qmd → .md, set up config, choose/customize theme, port styles, test)
- **Loss of Pandoc features** you may want for data science / medical content:
  - Executable code blocks (Python, R, Julia) rendered at build time
  - Native citation management with hover previews
  - Cross-references (`@fig-`, `@tbl-`, `@eq-`)
  - LaTeX equation rendering (Hugo has partial support via KaTeX/MathJax but Quarto's is more robust)
  - Callout blocks
- **Loss of 5 phases of completed work** — all the multilang extension, hreflang filter, translation banner, manifest script
- **New learning curve** — Hugo's template language (Go templates) vs Quarto's Lua/Pandoc filters

### The Verdict: Stay with Quarto

**The bug is a 15-line code change.** The entire multilingual infrastructure (5 phases, ~20 commits) is already built and working. The only problem is a regex that doesn't handle relative path depth. Switching to Hugo to solve a regex bug would be like moving houses because a light switch is wired wrong.

More importantly: this blog covers medicine, public health, and data science. Quarto's scientific publishing features (executable code, citations, equations) are directly relevant to future content. Hugo can't match these without significant plugin work.

**Recommendation:** Fix the navbar JS, ship the branch, move on to writing content.

### When Hugo *Would* Make Sense

- If you decide to never use Quarto's scientific features (unlikely given blog topics)
- If multilingual complexity keeps compounding (e.g., adding 5+ languages with complex routing)
- If you want to use a pre-built multilingual theme rather than hand-rolling one

None of these conditions are true today.

---

## Implementation Plan

### Task 1: Fix Navbar Link Rewriting (the actual bug)

**File:** `_includes/navbar-lang-switch.html`
**Action:** Replace relative-path regex with `URL` API resolution
**Lines affected:** 10–32 (nav link rewriting + brand link rewriting)
**Estimated effort:** 5 minutes

### Task 2: Render and Verify

**Action:** Run `quarto render`, then inspect navbar hrefs in rendered HTML at multiple depths
**Verification:** grep for nav-link hrefs in:
- `_site/fr/blog/index.html` (the page where the bug was first noticed)
- `_site/fr/blog/posts/2026-02-02-hello-world/index.html`

Note: the JS rewriting can't be verified by grepping static HTML (it runs client-side). Verify by opening in a browser or checking the JS logic manually.

### Task 3: Browser Test

**Action:** Open the site locally, reproduce the original bug path:
1. Go to root → auto-redirect (or manually go to `/fr/`)
2. Click "Blog" in navbar
3. Confirm it goes to `/fr/blog/index.html`, not `/en/blog/index.html`
4. From blog listing, click "About" → should go to `/fr/about.html`
5. Repeat from a blog post page (deepest nesting)

### Task 4: Commit

**Action:** Single commit with the fix, clear message

---

## Summary

| Aspect | Assessment |
|--------|-----------|
| **Bug severity** | High — breaks basic navigation for non-English users |
| **Root cause** | Regex in JS doesn't handle multi-level relative paths |
| **Fix complexity** | Low — single file, ~15 lines changed |
| **Hugo alternative** | Not justified — fixing a regex doesn't warrant a platform migration |
| **Risk** | Minimal — change is isolated to client-side nav rewriting |
