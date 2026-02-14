# Multilingual Site Design Plan

**Date:** 2026-02-04
**Status:** Draft
**Goal:** Make raphaelsimon.fr available in French and English, with potential for IT/ES/DE later

---

## Core Decisions

### URL Structure

Symmetric subdirectories — both languages are first-class citizens:

```
raphaelsimon.fr/
├── index.html          # Redirect (detects browser language)
├── en/
│   ├── index.qmd
│   ├── about.qmd
│   ├── contact.qmd
│   ├── thanks.qmd
│   └── blog/
│       ├── index.qmd
│       └── posts/
│           └── hello-world/
│               └── index.qmd
└── fr/
    ├── index.qmd
    ├── about.qmd
    ├── contact.qmd
    ├── thanks.qmd
    └── blog/
        ├── index.qmd
        └── posts/
            └── hello-world/
                └── index.qmd
```

**Rules:**
- All filenames are English (only content differs)
- Blog post slugs are English in both languages (ensure breadcrumbs display consistently to avoid confusion)
- Root redirects to `/fr/` or `/en/` based on browser `Accept-Language` (English fallback)

---

## Translation Management

### Quarto-Native Approach (Simplified)

**Use Quarto's built-in `_language.yml`** for UI strings instead of custom translation infrastructure.

**What Quarto's `_language.yml` covers automatically:**
- Search interface (placeholder, no results)
- TOC labels
- Listing pagination ("Next", "Previous")
- Code tools, callouts, cross-references

**What needs manual handling (minimal):**

| String | Solution |
|--------|----------|
| Navbar labels | Accept English ("Blog", "About", "Contact") — only "About" differs, minor trade-off. OR create custom navbar partial. |
| Footer copyright | Same in both languages ("© 2026 Raphaël Simon") — no translation needed |
| Contact form labels | Put directly in each `contact.qmd` file (separate files anyway) |
| Translation banner | Hardcode in Lua filter (only 2-3 strings) |

**Why this is simpler:**
- No custom `translations.yml` file
- No custom `{{< t >}}` shortcode
- No `translations.lua` filter
- Leverages Quarto's native i18n system

### Content Files (Tier 2)

All prose content lives in separate files per language:
- About page, contact page, blog posts
- Same filename in both language directories

**Homepage:**
- Each language has its own `index.qmd` (`/en/index.qmd`, `/fr/index.qmd`)
- Quarto listing automatically pulls from that language's `/blog/posts/` directory
- Sidebar content duplicated per language file (it's prose, not short strings)

### Alternative: babelquarto

[babelquarto](https://docs.ropensci.org/babelquarto/) is the community-endorsed R package for multilingual Quarto sites. It auto-generates language switchers and handles routing. **Not used here** because:
- Requires R dependency
- Uses suffix naming (`file.fr.qmd`) vs our subdirectory approach
- Our approach is simpler for this use case

---

## Blog Post Metadata

Single `translation` field in frontmatter:

```yaml
---
title: "Hello World"
date: 2026-02-02
categories: [meta, welcome]
translation: none    # none | machine
---
```

| `translation` | Meaning | Display |
|---------------|---------|---------|
| `none` | You wrote this (original or manual translation) | No banner |
| `machine` | LLM translated this | Banner with link to original(s) |
| File missing | Not available in this language | Not shown in that language's listing |

**Banner logic for machine-translated posts:**
- At build time, find all other language versions with `translation: none`
- Display: "Machine-translated — Original in: 🇫🇷" (or multiple flags if multiple originals)

**Implementation approach (Lua filter + manifest):**
1. Pre-render script scans all posts and generates `_data/translations-manifest.json` mapping slugs to their language versions and translation status
2. Lua filter runs during Quarto/Pandoc processing, reads the manifest, and renders the banner
3. This approach is future-proof: adding IT/ES/DE just means updating the manifest scan — Lua filter logic stays unchanged

---

## Language Switcher

**Navbar (right side):**
```
[Blog] [About] [Contact]                    🇫🇷 🌐  [GitHub] [LinkedIn] [Bluesky] [RSS]
```
- Flag shows current language
- Globe opens dropdown with all available languages

**Footer:**
```
© 2026 Raphaël Simon                                          🇫🇷 Français  🌐
```
- Current language with text label
- Globe opens same dropdown

**Dropdown content:**
```
┌─────────────┐
│ 🇫🇷 Français │
│ 🇬🇧 English  │
└─────────────┘
```
- Current language visually indicated (muted or checkmark)
- Links to equivalent page in other language
- If equivalent doesn't exist, links to that language's homepage

**How switcher knows equivalent exists:**
- For static pages (about, contact, thanks): equivalents always exist (both languages have all static pages)
- For blog posts: switcher reads from `_data/translations-manifest.json` (same manifest used by translation banner)

**Implementation:** Quarto shortcode extension (not plain HTML partial — partials can't have logic)
- Shortcode reads current page's `lang` and path
- For blog posts, checks manifest for equivalent in other language
- Renders appropriate link (equivalent page or homepage fallback)
- CSS handles dropdown styling

---

## Search

**V1 Implementation (Phase 4):**
- Quarto creates a **single global search index** (`_site/search.json`) including all languages
- Search results include both English and French content
- Language flags (🇫🇷 🇬🇧) added inline to each result for clarity
- Uses Quarto's built-in overlay search with custom CSS for flag display

```
┌─────────────────────────────────────┐
│ Search...                           │
├─────────────────────────────────────┤
│ 🇫🇷 Bonjour le monde                │
│ 🇬🇧 Hello World                     │
│ 🇫🇷 À propos                        │
└─────────────────────────────────────┘
```

**Implementation Details:**
- Search index: `_site/search.json` (global, all languages)
- Language detection: Parse URL path (`/en/` vs `/fr/`)
- Flag rendering: CSS `:before` pseudo-element based on `href` attribute
- No JavaScript modifications required

**V2 (nice-to-have, later):**
- Results grouped by language with flag headers
- Search filtering by language
- Requires custom search results renderer with JavaScript

---

## SEO & Technical

### hreflang Tags

Every page includes in `<head>`:
```html
<link rel="alternate" hreflang="en" href="https://raphaelsimon.fr/en/about/" />
<link rel="alternate" hreflang="fr" href="https://raphaelsimon.fr/fr/about/" />
<link rel="alternate" hreflang="x-default" href="https://raphaelsimon.fr/en/about/" />
```

**Implementation approach (Lua filter):**
- Quarto has NO built-in hreflang support
- Use a Lua filter that reads explicit `hreflang` metadata from each page's frontmatter:
  ```yaml
  hreflang:
    en: "/en/about/"
    fr: "/fr/about/"
  ```
- Only generates hreflang tags for translations that are explicitly declared
- Gracefully handles missing translations: if no `fr` key, no French hreflang tag
- This explicit approach avoids referencing non-existent pages

**Note on field naming:**
- `translation: none | machine` — Used by blog posts to indicate if content is original or machine-translated (for banner display)
- `hreflang: { en: "...", fr: "..." }` — Used by all pages to declare alternate language URLs (for SEO)
- These serve different purposes and are intentionally separate

### RSS Feeds

Per-language RSS feeds:
- `/en/blog/index.xml` for English posts
- `/fr/blog/index.xml` for French posts
- Navbar RSS icon links to current language's feed

### Root Redirect

**Trade-off note:** GitHub Pages does not support server-side redirects or Accept-Language detection. JavaScript redirect is the only option. Users with JS disabled get the noscript fallback (English). This affects <2% of traffic and is acceptable.

`index.html` at root:
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

### Quarto Config Structure

**Root `_quarto.yml`:**
- Site URL, project type, output directory
- Theme settings (darkly/flatly)
- Shared features (TOC, code folding, search)
- Social icons (right navbar)

**`en/_metadata.yml`:**
```yaml
lang: en
author: "Raphaël Simon"
# Quarto auto-loads English UI strings from built-in _language.yml
```

**`fr/_metadata.yml`:**
```yaml
lang: fr
author: "Raphaël Simon"
# Quarto auto-loads French UI strings from built-in _language.yml
# Override specific strings if needed:
language:
  toc-title-document: "Sur cette page"
```

**Note:** Quarto includes built-in translations for French. Setting `lang: fr` automatically uses French UI strings for search, TOC, listings, etc. Only override if the built-in translation isn't suitable.

---

## Future: Additional Languages

IT/ES/DE can be added as machine-translated versions:
- Same directory structure: `/it/`, `/es/`, `/de/`
- All posts would have `translation: machine`
- Language switcher dropdown scales naturally
- Search includes all languages with appropriate flags

---

## Implementation Phases

### Phase 1: Structure
- Create `/en/` and `/fr/` directories
- **Copy** existing files (`index.qmd`, `about.qmd`, `contact.qmd`, `thanks.qmd`, `blog/`) into `/en/`
- **Duplicate** structure into `/fr/` with same filenames (content stays English initially — translate in Phase 2)
- Move `blog/posts/` content to `/en/blog/posts/` and create empty `/fr/blog/posts/`
- Set up root `index.html` redirect
- Create `_metadata.yml` for each language (`lang: en` / `lang: fr`)
- Update `_quarto.yml`: remove root-level content references, point to language subdirectories
- Keep `_includes/`, `_extensions/`, `scripts/`, `_data/`, `images/` at project root (shared across languages)
- Verify site builds and both `/en/` and `/fr/` render correctly (content can be same language temporarily)

### Phase 2: Content Translation
- Translate `fr/about.qmd` content to French
- Translate `fr/contact.qmd` content to French (including form labels — they're in the file itself)
- Translate `fr/index.qmd` homepage content to French
- Translate `fr/thanks.qmd` to French
- Verify Quarto's built-in UI strings render in French (TOC, search) via `lang: fr` in `_metadata.yml`
- Note: Form validation messages are browser-native and auto-localize based on `lang`

### Phase 3: Language Switcher
- Create `_extensions/multilang/` extension structure
- Implement `lang-switch.lua` shortcode that renders flag + globe dropdown
- Add `{{< lang-switch >}}` to navbar partial (via `_quarto.yml` navbar config or custom include)
- Add `{{< lang-switch >}}` to footer partial
- CSS for dropdown styling (prefer CSS-only hover, JS click as fallback)
- Shortcode reads manifest for blog posts, assumes equivalents exist for static pages

### Phase 4: Blog & Search
- Add `translation` field to blog post template/metadata defaults
- Implement machine-translation banner (Lua filter + manifest)
- Test Quarto's search behavior with split directories:
  - If per-language: accept and ship (no custom work needed)
  - If global: add flag prefix to results (custom JS in search config)

### Phase 5: SEO
- Create `hreflang.lua` filter
- Add `hreflang` frontmatter to static pages (about, contact, etc.)
- Update pre-render script to auto-generate `hreflang` for blog posts
- Verify hreflang tags render correctly in HTML output
- Test sitemap includes all languages
- Validate with Google Search Console (after deployment)

---

## Technical Implementation Notes

### Quarto Extensions Required

Create as Quarto extension in `_extensions/multilang/`:

**Lua Filters:**

1. **`translation-banner.lua`** — Renders machine-translation banner on blog posts
   - Reads `_data/translations-manifest.json` (generated by pre-render script)
   - Checks current post's `translation` field
   - If `machine`, finds originals and renders banner with flags
   - Banner text hardcoded per language (only 2-3 strings, not worth external config)

2. **`hreflang.lua`** — Injects hreflang tags into `<head>`
   - Reads `hreflang` metadata from page frontmatter
   - Generates `<link rel="alternate" hreflang="...">` for each declared translation
   - Only references pages that actually exist

**Shortcodes:**

3. **`lang-switch.lua`** — Language switcher shortcode
   - Usage: `{{< lang-switch >}}` in navbar/footer partials
   - Reads current page's `lang` and constructs equivalent URL in other language
   - For blog posts, checks manifest; for static pages, assumes equivalent exists
   - Renders flag + globe dropdown HTML

### Pre-render Script

A Python script (`scripts/build-manifest.py`) that:
1. Scans `/en/blog/posts/` and `/fr/blog/posts/`
2. Extracts frontmatter from each post (using `python-frontmatter` library)
3. Outputs `_data/translations-manifest.json` mapping slugs to language versions and translation status
4. Optionally: auto-generates `hreflang` frontmatter for blog posts based on which translations exist (reduces manual maintenance)

**Build process integration (Quarto-native):**

Use Quarto's `project: pre-render:` hook in `_quarto.yml`:

```yaml
project:
  type: website
  pre-render:
    - scripts/build-manifest.py
```

This runs the script automatically before every `quarto render` — no manual step or wrapper script needed.

`_data/` folder lives at project root (alongside `_quarto.yml`).

**hreflang maintenance:**
- Static pages (about, contact, etc.): Manually add `hreflang` to frontmatter once (these rarely change)
- Blog posts: Pre-render script can auto-inject `hreflang` based on manifest, OR manually maintain per-post
- Recommendation: Auto-generate for blog posts to reduce maintenance burden

### Deferred Improvements (V2)

- Grouped search results by language with flag headers
- Custom search renderer (if Quarto's default doesn't support grouping)

---

## Open Questions

None — all decisions captured above.

---

## Review Response Log

**2026-02-04:** Addressed concerns from design review:

1. **Translation banner complexity** → Lua filter + manifest script approach (future-proof, scales to N languages)
2. **hreflang maintenance** → Lua filter with explicit `hreflang` frontmatter (handles missing translations gracefully)
3. **Search across languages** → Accept Quarto's default behavior; improve later if needed
4. **Root redirect fragility** → Documented GitHub Pages limitation; JS redirect is only option
5. **translations.yml editing** → Not a concern; only blog posts need phone-friendly editing
6. **English slugs** → Intentional; added breadcrumb consistency reminder
7. **RSS feeds** → Per-language: `/en/blog/index.xml`, `/fr/blog/index.xml`
8. **Contact form** → Labels directly in each `contact.qmd` file; validation is browser-native

**2026-02-04:** Aligned with Quarto-native patterns:

1. **Replaced custom `translations.yml`** → Use Quarto's built-in `_language.yml` and `lang:` setting
2. **Eliminated `{{< t >}}` shortcode** → Not needed; UI strings covered by Quarto, prose in separate files
3. **Pre-render script** → Use `project: pre-render:` in `_quarto.yml` (Quarto-native hook)
4. **Language switcher** → Quarto shortcode extension, not plain HTML partial (partials can't have logic)
5. **Added babelquarto note** → Documented as alternative, not used (requires R dependency)
6. **Simplified Phase 2** → Now just content translation, no infrastructure to build
