# Phase 5: SEO Implementation Plan

**Status:** Ready for execution  
**Dependencies:** Phase 1-4 complete (multilingual structure, content, switcher, search)

---

## Overview

This phase implements SEO optimizations for multilingual content:
- hreflang tags for language alternates
- Auto-generated hreflang mappings for blog posts
- Sitemap verification for all languages
- Google Search Console validation checklist

---

## Task 1: Create hreflang.lua Filter

**File:** `_extensions/multilang/hreflang.lua`

**Implementation:**

```lua
-- hreflang.lua: Injects hreflang tags into <head> based on frontmatter metadata

function Meta(meta)
  if not meta.hreflang then
    return meta
  end
  
  local hreflang_tags = {}
  local base_url = "https://raphaelsimon.fr"
  
  -- Iterate through hreflang metadata
  for lang_code, path in pairs(meta.hreflang) do
    local href = base_url .. pandoc.utils.stringify(path)
    local tag = string.format(
      '<link rel="alternate" hreflang="%s" href="%s" />',
      pandoc.utils.stringify(lang_code),
      href
    )
    table.insert(hreflang_tags, tag)
  end
  
  -- Add x-default (point to English)
  if meta.hreflang.en then
    local default_href = base_url .. pandoc.utils.stringify(meta.hreflang.en)
    local default_tag = string.format(
      '<link rel="alternate" hreflang="x-default" href="%s" />',
      default_href
    )
    table.insert(hreflang_tags, default_tag)
  end
  
  -- Inject into header-includes
  if #hreflang_tags > 0 then
    local html = table.concat(hreflang_tags, "\n")
    if meta['header-includes'] then
      table.insert(meta['header-includes'], pandoc.RawBlock('html', html))
    else
      meta['header-includes'] = pandoc.MetaList{pandoc.RawBlock('html', html)}
    end
  end
  
  return meta
end
```

**Success criteria:**
- File exists at `_extensions/multilang/hreflang.lua`
- Lua syntax is valid (no parse errors)
- Filter reads `hreflang` from page metadata
- Generates `<link rel="alternate">` tags for each declared language
- Includes `hreflang="x-default"` pointing to English version
- Injects tags into `header-includes` metadata

---

## Task 2: Register hreflang Filter in Extension

**File:** `_extensions/multilang/_extension.yml`

**Note:** This file should already exist from Phase 3 (Language Switcher implementation).

**Action:** Add hreflang.lua to filters list

**Before:**
```yaml
contributes:
  filters:
    - translation-banner.lua
  shortcodes:
    - lang-switch.lua
```

**After:**
```yaml
contributes:
  filters:
    - translation-banner.lua
    - hreflang.lua
  shortcodes:
    - lang-switch.lua
```

**Success criteria:**
- `hreflang.lua` appears in filters list
- Extension YAML is valid
- `quarto render` loads filter without errors

---

## Task 3: Add hreflang Metadata to Static Pages

**Files to edit:**
- `/en/index.qmd`
- `/en/about.qmd`
- `/en/contact.qmd`
- `/en/thanks.qmd`
- `/fr/index.qmd`
- `/fr/about.qmd`
- `/fr/contact.qmd`
- `/fr/thanks.qmd`

**Example for `/en/about.qmd`:**

**Add to frontmatter:**
```yaml
hreflang:
  en: "/en/about/"
  fr: "/fr/about/"
```

**Example for `/fr/index.qmd`:**

**Add to frontmatter:**
```yaml
hreflang:
  en: "/en/"
  fr: "/fr/"
```

**Mapping table for all static pages:**

| File | en path | fr path |
|------|---------|---------|
| index.qmd | `/en/` | `/fr/` |
| about.qmd | `/en/about/` | `/fr/about/` |
| contact.qmd | `/en/contact/` | `/fr/contact/` |
| thanks.qmd | `/en/thanks/` | `/fr/thanks/` |

**Success criteria:**
- All 8 static pages have `hreflang` frontmatter
- Paths match URL structure (trailing slashes included)
- Both language versions reference each other symmetrically
- YAML frontmatter is valid

---

## Task 4: Extend Pre-render Script for hreflang Auto-generation

**File:** `scripts/build-manifest.py`

**Current behavior:** Generates `_data/translations-manifest.json` with blog post translation mappings

**New behavior:** Auto-generate hreflang metadata for blog posts by injecting it into frontmatter

**Note:** The script runs from the project root (via Quarto's `project: pre-render:` hook in `_quarto.yml`). All file paths are relative to project root.

**Required dependency:** `python-frontmatter` library (for reading/writing YAML frontmatter)

**Implementation:**

After building the translations manifest, add:

```python
import os
from pathlib import Path

def generate_hreflang_metadata(manifest):
    """
    Generate hreflang frontmatter for blog posts based on manifest.
    Returns dict: {slug: {en: path, fr: path, ...}}
    """
    hreflang_map = {}
    
    for slug, data in manifest.items():
        hreflang_map[slug] = {}
        for lang_code in data.get('languages', []):
            hreflang_map[slug][lang_code] = f"/{lang_code}/blog/posts/{slug}/"
    
    return hreflang_map

def inject_hreflang_into_posts(hreflang_map):
    """
    Update blog post frontmatter with hreflang metadata.
    Uses forward slashes (os.path.join) for cross-platform compatibility.
    """
    for slug, hreflang_data in hreflang_map.items():
        for lang_code, path in hreflang_data.items():
            post_path = os.path.join(lang_code, "blog", "posts", slug, "index.qmd")
            if not os.path.exists(post_path):
                continue
            
            # Read current frontmatter
            with open(post_path, 'r', encoding='utf-8') as f:
                post = frontmatter.load(f)
            
            # Inject or update hreflang
            post.metadata['hreflang'] = hreflang_data
            
            # Write back
            with open(post_path, 'w', encoding='utf-8') as f:
                f.write(frontmatter.dumps(post))

# Add to main execution
if __name__ == "__main__":
    manifest = scan_posts()
    save_manifest(manifest)
    
    # Auto-inject hreflang into blog posts
    hreflang_map = generate_hreflang_metadata(manifest)
    inject_hreflang_into_posts(hreflang_map)
```

**Why direct frontmatter injection:** hreflang is a page property, not runtime data. Storing it in frontmatter keeps the page self-contained and matches the approach used for static pages (Task 3).

**Success criteria:**
- Script generates hreflang metadata for all blog posts with translations
- Frontmatter in blog post `index.qmd` files contains `hreflang` field
- Paths match pattern `/{lang}/blog/posts/{slug}/`
- Script runs without errors as part of pre-render hook

---

## Task 5: Verify hreflang Output in HTML

**Commands:**
```bash
quarto render
```

**Verification steps:**

1. **Check English about page:**
```bash
grep -A 3 'rel="alternate"' _site/en/about/index.html
```

Expected output:
```html
<link rel="alternate" hreflang="en" href="https://raphaelsimon.fr/en/about/" />
<link rel="alternate" hreflang="fr" href="https://raphaelsimon.fr/fr/about/" />
<link rel="alternate" hreflang="x-default" href="https://raphaelsimon.fr/en/about/" />
```

2. **Check French homepage:**
```bash
grep -A 3 'rel="alternate"' _site/fr/index.html
```

Expected output:
```html
<link rel="alternate" hreflang="en" href="https://raphaelsimon.fr/en/" />
<link rel="alternate" hreflang="fr" href="https://raphaelsimon.fr/fr/" />
<link rel="alternate" hreflang="x-default" href="https://raphaelsimon.fr/en/" />
```

3. **Check blog post with translations:**
```bash
# Assuming hello-world exists in both languages
grep -A 3 'rel="alternate"' _site/en/blog/posts/hello-world/index.html
```

Expected output:
```html
<link rel="alternate" hreflang="en" href="https://raphaelsimon.fr/en/blog/posts/hello-world/" />
<link rel="alternate" hreflang="fr" href="https://raphaelsimon.fr/fr/blog/posts/hello-world/" />
<link rel="alternate" hreflang="x-default" href="https://raphaelsimon.fr/en/blog/posts/hello-world/" />
```

4. **Check blog post that exists only in one language:**

If a post exists only in `/en/blog/posts/example/` but not in French:

```bash
grep -A 3 'rel="alternate"' _site/en/blog/posts/example/index.html
```

Expected output:
```html
<link rel="alternate" hreflang="en" href="https://raphaelsimon.fr/en/blog/posts/example/" />
<link rel="alternate" hreflang="x-default" href="https://raphaelsimon.fr/en/blog/posts/example/" />
```

(Only English hreflang, no French — filter only includes declared translations)

**Success criteria:**
- All static pages render hreflang tags
- Blog posts with translations include all language alternates
- Blog posts without translations include only available languages
- `x-default` always points to English version
- Full URLs include `https://raphaelsimon.fr` prefix
- Tags appear in `<head>` section of HTML

---

## Task 6: Verify Sitemap Includes All Languages

**File to check:** `_site/sitemap.xml`

**Quarto auto-generates `sitemap.xml`** based on the `website.site-url` configured in `_quarto.yml`. No manual sitemap creation needed.

**Command:**
```bash
cat _site/sitemap.xml | grep -E '<loc>.*/(en|fr)/' | head -20
```

**Expected behavior:**
- Sitemap includes URLs for both `/en/` and `/fr/` directories
- All static pages appear in both languages
- Blog posts appear per available translation (not all posts need both)

**Example entries:**
```xml
<url>
  <loc>https://raphaelsimon.fr/en/</loc>
</url>
<url>
  <loc>https://raphaelsimon.fr/fr/</loc>
</url>
<url>
  <loc>https://raphaelsimon.fr/en/about/</loc>
</url>
<url>
  <loc>https://raphaelsimon.fr/fr/about/</loc>
</url>
```

**Quarto sitemap configuration check:**

Verify `_quarto.yml` includes:
```yaml
website:
  site-url: "https://raphaelsimon.fr"
```

This ensures sitemap uses canonical domain.

**Success criteria:**
- Sitemap exists at `_site/sitemap.xml`
- Sitemap includes entries for `/en/` and `/fr/` subdirectories
- Site URL uses `https://raphaelsimon.fr` (no trailing slash)
- All rendered pages appear in sitemap
- No 404 or placeholder pages included

---

## Task 7: Verify Canonical URL Configuration

**Check `_quarto.yml`:**

```yaml
website:
  site-url: "https://raphaelsimon.fr"
```

**Check rendered HTML:**

```bash
grep 'rel="canonical"' _site/en/about/index.html
grep 'rel="canonical"' _site/fr/about/index.html
```

**Expected behavior:**
- Quarto auto-generates canonical tags pointing to the SAME language version of each page
- English page canonical: `https://raphaelsimon.fr/en/about/`
- French page canonical: `https://raphaelsimon.fr/fr/about/`
- No cross-language canonical conflicts

**Success criteria:**
- Canonical URLs exist in rendered HTML (auto-generated by Quarto)
- Each page's canonical points to itself (same language version)
- Format: `<link rel="canonical" href="https://raphaelsimon.fr/{lang}/path/" />`

**If canonical tags are missing:** This indicates a Quarto configuration issue unrelated to Phase 5 SEO implementation. Investigate `_quarto.yml` settings.

---

## Task 8: Manual Google Search Console Verification Checklist

**Note:** This task requires deployment to production. Steps below are for post-deployment validation.

**Pre-deployment checklist:**
1. All hreflang tags render correctly (verified in Task 5)
2. Sitemap includes all languages (verified in Task 6)
3. Canonical URLs are correct (verified in Task 7)
4. Site URL in `_quarto.yml` matches production domain

**Post-deployment steps:**

### 8.1: Submit Sitemap to Google Search Console

1. Navigate to Google Search Console → Sitemaps
2. Submit sitemap URL: `https://raphaelsimon.fr/sitemap.xml`
3. Wait 24-48 hours for indexing

### 8.2: Validate hreflang Implementation

1. Navigate to: https://search.google.com/search-console/links/drilldown/alternate
2. Or use: Settings → International Targeting → Language tags
3. Check for hreflang errors:
   - "No return tag" — One language page references another, but reverse link missing
   - "Incorrect hreflang value" — Invalid language code
   - "Referenced URL not indexed" — hreflang points to non-existent page

**Common issues and fixes:**

| Error | Cause | Fix |
|-------|-------|-----|
| No return tag | Asymmetric hreflang (EN → FR exists, FR → EN missing) | Ensure both pages reference each other in frontmatter |
| Referenced URL not indexed | hreflang points to page that doesn't exist | Remove hreflang entry for missing translation |
| x-default missing | No x-default specified | hreflang.lua should auto-add this (verify code) |

### 8.3: Test Search Results in Different Locales

1. Open Google in incognito mode
2. Set search locale to France (google.fr)
3. Search: `site:raphaelsimon.fr about`
4. Verify French page (`/fr/about/`) appears for French locale
5. Repeat with google.com for English

**Expected behavior:**
- Google.fr shows `/fr/` pages when available
- Google.com shows `/en/` pages
- Search snippets display in appropriate language

### 8.4: Validate with hreflang Testing Tool

Use external validator:
1. Visit: https://www.aleydasolis.com/english/international-seo-tools/hreflang-tags-generator/
2. Enter URL: `https://raphaelsimon.fr/en/about/`
3. Tool will crawl and validate hreflang implementation

**Success criteria:**
- No critical errors reported
- All declared languages detected
- x-default present
- Bidirectional links verified

### 8.5: Monitor Index Coverage

1. Google Search Console → Index → Coverage
2. Check for:
   - All language pages indexed (both `/en/` and `/fr/`)
   - No "Duplicate without user-selected canonical" errors
   - No excluded pages due to hreflang conflicts

**Baseline metrics to track:**
- Total indexed pages (should include both languages)
- Pages with hreflang tags detected
- Language distribution in search results by country

---

## Rollback Plan

If hreflang implementation causes indexing issues:

**Immediate rollback:**
```bash
# Remove hreflang filter from extension
# Edit _extensions/multilang/_extension.yml:
# Comment out hreflang.lua from filters list
quarto render
git add _site/
git commit -m "Rollback: disable hreflang filter"
git push
```

**Partial rollback (static pages only):**
```bash
# Remove hreflang from blog posts
# Edit scripts/build-manifest.py: comment out the inject_hreflang_into_posts() call
# Keep hreflang on static pages (manually verified)
quarto render
```

**Rollback to disable auto-generation only:**
```bash
# If auto-generated hreflang in blog posts causes issues but static pages are fine:
# Edit scripts/build-manifest.py: comment out lines that call generate_hreflang_metadata() and inject_hreflang_into_posts()
quarto render
```

**Debugging hreflang issues:**

1. **Check Google Search Console errors** → Identifies specific pages with problems
2. **Validate HTML output** → Use grep commands from Task 5
3. **Test single page** → Isolate problem (static vs blog vs specific post)
4. **Check Lua filter logs** → Add debug prints to hreflang.lua if needed

---

## Testing Checklist

Before marking Phase 5 complete:

- [ ] `hreflang.lua` filter exists and is registered
- [ ] All static pages (8 files) have hreflang frontmatter
- [ ] Pre-render script auto-generates hreflang for blog posts
  - Verify: `grep -l "hreflang:" en/blog/posts/*/index.qmd fr/blog/posts/*/index.qmd` shows files with hreflang metadata
- [ ] `quarto render` completes without errors
- [ ] HTML output contains hreflang tags in `<head>`
- [ ] hreflang tags reference only existing translations
- [ ] x-default points to English version
- [ ] Sitemap includes all languages
- [ ] Canonical URLs point to same-language version
- [ ] Site URL in config matches production domain

Post-deployment (manual):
- [ ] Sitemap submitted to Google Search Console
- [ ] hreflang validation shows no critical errors
- [ ] Search results display appropriate language by locale
- [ ] External hreflang validator shows no issues
- [ ] Index coverage shows both languages indexed

---

## Success Criteria Summary

**Phase 5 is complete when:**

1. All rendered HTML pages include correct hreflang tags
2. Static pages have manually declared hreflang frontmatter
3. Blog posts auto-generate hreflang based on available translations
4. Sitemap includes all language versions
5. No hreflang errors in local HTML validation
6. Pre-deployment checklist passes
7. Manual GSC verification steps documented for post-deployment

**Verification command:**
```bash
# Quick validation that hreflang is working
quarto render && \
grep -l 'hreflang=' _site/en/index.html _site/fr/index.html _site/en/about/index.html && \
echo "✓ hreflang tags present in rendered HTML"
```

---

## Notes

- **hreflang vs translation field:** These serve different purposes
  - `translation: none|machine` — Controls banner display on blog posts
  - `hreflang: {en: ..., fr: ...}` — SEO metadata for search engines
- **Static pages always have equivalents** — All static pages exist in both languages
- **Blog posts may not** — hreflang filter gracefully handles missing translations
- **x-default convention** — Points to English as fallback for unmatched locales
- **Trailing slashes** — Match Quarto's URL structure (e.g., `/en/about/` not `/en/about`)
- **Pre-render automation** — Reduces manual maintenance burden for blog posts
