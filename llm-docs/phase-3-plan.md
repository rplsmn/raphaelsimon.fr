# Phase 3: Language Switcher - Implementation Plan

**Date:** 2026-02-04  
**Status:** Ready for execution  
**Goal:** Implement language switcher UI component in navbar and footer with flag + globe dropdown

---

## Overview

This phase creates the visual language switcher that appears on every page. The switcher:
- Shows current language as a flag (🇫🇷 or 🇬🇧)
- Opens dropdown on hover/click with all available languages
- Links to equivalent page in other language (or homepage if equivalent doesn't exist)
- Appears in both navbar (right side) and footer (right side)

For Phase 3, **we focus on static pages only** (about, contact, thanks). Blog post equivalents are deferred to Phase 4 (when manifest is built).

**Safe fallback for blog posts:** If no manifest exists, link to target language's homepage.

**Blog Post URL Routing:** Quarto renders posts to `/LANG/blog/posts/SLUG/index.html`.
Language switcher must account for this during Phase 4 manifest parsing.
Phase 3 falls back to homepage for all blog posts (no manifest exists).

---

## Task Breakdown

### Task 1: Create Extension Directory Structure

**Files to create:**
- `_extensions/multilang/_extension.yml`

**Actions:**
```bash
mkdir -p _extensions/multilang
```

Create `_extensions/multilang/_extension.yml`:
```yaml
title: Multilingual Support
author: Raphaël Simon
version: 1.0.0
quarto-required: ">=1.4.0"
contributes:
  shortcodes:
    - lang-switch.lua
```

**Success criteria:**
- Directory `_extensions/multilang/` exists
- `_extension.yml` is valid YAML and declares shortcode

---

### Task 2: Implement Language Switcher Shortcode

**Files to create:**
- `_extensions/multilang/lang-switch.lua`

**Behavior:**
- Reads current page's `lang` from metadata (falls back to `en`)
- Determines current page path relative to language root
- Constructs equivalent URL in other language:
  - For static pages: assumes same path exists under other language (`/en/about/` → `/fr/about/`)
  - For blog posts: checks if `_data/translations-manifest.json` exists and reads it; if not, falls back to homepage
- Renders HTML with current flag + globe icon + dropdown
- Dropdown lists all languages (FR, EN) with flags
- Current language is visually indicated (muted or with checkmark)

**Implementation:**

Create `_extensions/multilang/lang-switch.lua`:

```lua
function Shortcode(args, kwargs, meta)
  -- Get current language from page metadata
  local current_lang = "en"
  if meta.lang and pandoc.utils.stringify(meta.lang) then
    current_lang = pandoc.utils.stringify(meta.lang)
  end
  
  -- Get current page path (relative to site root)
  local current_path = ""
  if quarto.doc.input_file then
    current_path = quarto.doc.input_file
  end
  
  -- Validate current_path structure
  if current_path == "" then
    current_path = current_lang .. "/index.qmd"
  end
  
  -- Define language mappings in order
  local languages = {
    en = {flag = "🇬🇧", label = "English"},
    fr = {flag = "🇫🇷", label = "Français"}
  }
  local lang_order = {"en", "fr"}
  
  -- Function to construct target URL
  local function get_target_url(target_lang)
    -- For static pages: assume symmetric structure
    -- /en/about.qmd → /fr/about/
    -- /en/contact.qmd → /fr/contact/
    -- /en/index.qmd → /fr/
    
    if current_path:match("^" .. current_lang .. "/blog/posts/") then
      -- Blog post: manifest-based linking is Phase 4 work
      -- Phase 3: always fallback to homepage (safe, no broken links)
      return "/" .. target_lang .. "/"
    else
      -- Static page: replace language prefix
      local path_without_lang = current_path:gsub("^" .. current_lang .. "/", "")
      local target_path = "/" .. target_lang .. "/" .. path_without_lang
      
      -- Convert .qmd to .html and adjust path
      target_path = target_path:gsub("%.qmd$", ".html")
      target_path = target_path:gsub("index%.html$", "")
      
      return target_path
    end
  end
  
  -- Build HTML for switcher
  local html = [[
<div class="lang-switcher">
  <span class="current-lang">]] .. languages[current_lang].flag .. [[</span>
  <button class="lang-globe" aria-label="Switch language">🌐</button>
  <div class="lang-dropdown">
]]
  
  -- Add links for each language (in order: en, fr)
  for _, lang_code in ipairs(lang_order) do
    local lang_data = languages[lang_code]
    local is_current = (lang_code == current_lang)
    local css_class = is_current and "lang-option current" or "lang-option"
    local target_url = is_current and "#" or get_target_url(lang_code)
    
    html = html .. [[
    <a href="]] .. target_url .. [[" class="]] .. css_class .. [[">
      ]] .. lang_data.flag .. [[ ]] .. lang_data.label .. [[
    </a>
]]
  end
  
  html = html .. [[
  </div>
</div>
]]
  
  return pandoc.RawBlock('html', html)
end

return {
  ['lang-switch'] = Shortcode
}
```

**Success criteria:**
- Lua file is syntactically valid
- Returns HTML with current flag, globe button, and dropdown structure
- Constructs correct URLs for static pages
- Falls back to homepage for blog posts (Phase 4 will improve this)

---

### Task 3: Add CSS Styling for Switcher

**Files to modify:**
- `styles.css`

**Actions:**

Add to `styles.css`:

```css
/* Language Switcher */
.lang-switcher {
  position: relative;
  display: inline-flex;
  align-items: center;
  gap: 0.25rem;
}

.lang-switcher .current-lang {
  font-size: 1.2rem;
}

.lang-switcher .lang-globe {
  background: none;
  border: none;
  font-size: 1.2rem;
  cursor: pointer;
  padding: 0;
  margin: 0;
  line-height: 1;
}

.lang-switcher .lang-globe:hover {
  opacity: 0.7;
}

.lang-switcher .lang-dropdown {
  display: none;
  position: absolute;
  top: 100%;
  right: 0;
  margin-top: 0.5rem;
  background: var(--bs-body-bg);
  border: 1px solid var(--bs-border-color);
  border-radius: 0.25rem;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
  min-width: 150px;
  z-index: 1000;
}

.lang-switcher:hover .lang-dropdown,
.lang-switcher .lang-globe:focus + .lang-dropdown {
  display: block;
}

.lang-dropdown .lang-option {
  display: block;
  padding: 0.5rem 1rem;
  color: var(--bs-body-color);
  text-decoration: none;
  white-space: nowrap;
}

.lang-dropdown .lang-option:hover {
  background: var(--bs-secondary-bg);
}

.lang-dropdown .lang-option.current {
  opacity: 0.5;
  cursor: default;
  pointer-events: none;
}

/* Navbar integration */
.navbar .lang-switcher {
  margin-left: 1rem;
}

/* Footer integration */
.page-footer .lang-switcher {
  display: inline-flex;
}
```

**Success criteria:**
- CSS is valid
- Dropdown is hidden by default
- Dropdown appears on hover over globe button
- Current language is visually muted
- Styling works with both dark and light themes (uses CSS variables)

---

### Task 4: Add Switcher to Navbar

**Strategy:** Use Quarto shortcode support in navbar text field.

**Files to create:**
- None (if shortcode works directly in navbar config)

**Files to modify:**
- `_quarto.yml`

**Actions:**

Update `_quarto.yml` to include language switcher in navbar right section:

```yaml
  navbar:
    background: dark
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
        href: en/blog/index.xml
        aria-label: RSS Feed
      - text: |
          {{< lang-switch >}}
```

**If shortcode doesn't work in navbar text:**

Create `_includes/navbar-custom.html`:
```html
<div class="navbar-lang-switcher">
  {{< lang-switch >}}
</div>
```

Then check if Quarto supports `navbar:` as a template location in `_quarto.yml`. If not, use raw HTML fallback with JavaScript language detection (documented in Phase 3 implementation notes).

**Success criteria:**
- Language switcher appears in navbar (right side)
- Switcher is visible on all pages
- No build errors related to shortcode or navbar configuration

---

### Task 5: Add Switcher to Footer

**Files to modify:**
- `_quarto.yml`

**Actions:**

Quarto's `page-footer` in `_quarto.yml` supports shortcodes in right section:

```yaml
  page-footer:
    left: |
      © 2026 Raphaël Simon
    right: |
      {{< lang-switch >}}
```

**If shortcode doesn't work in footer:**

Create `_includes/footer-lang-switcher.html`:
```html
<div class="footer-lang-switcher">
  {{< lang-switch >}}
</div>
```

Then update `_quarto.yml` with full HTML structure for footer.

**Success criteria:**
- Language switcher appears in footer (right side)
- Switcher is visible on all pages
- No build errors

---

### Task 6: Add JavaScript Click Fallback (Optional)

**Purpose:** Some users may have CSS hover issues on mobile. Add click handler as fallback.

**Files to create:**
- `_includes/lang-switcher-script.html`

**Files to modify:**
- `_quarto.yml` (add to `format: html: include-after-body:`)

**Actions:**

Create `_includes/lang-switcher-script.html`:
```html
<script>
document.addEventListener('DOMContentLoaded', function() {
  const globeButtons = document.querySelectorAll('.lang-globe');
  
  globeButtons.forEach(button => {
    button.addEventListener('click', function(e) {
      e.preventDefault();
      const dropdown = this.nextElementSibling;
      
      // Toggle display
      if (dropdown.style.display === 'block') {
        dropdown.style.display = 'none';
      } else {
        // Hide all other dropdowns first
        document.querySelectorAll('.lang-dropdown').forEach(d => {
          d.style.display = 'none';
        });
        dropdown.style.display = 'block';
      }
    });
  });
  
  // Close dropdown when clicking outside
  document.addEventListener('click', function(e) {
    if (!e.target.closest('.lang-switcher')) {
      document.querySelectorAll('.lang-dropdown').forEach(d => {
        d.style.display = 'none';
      });
    }
  });
});
</script>
```

Add to `_quarto.yml` under `format: html:`:
```yaml
format:
  html:
    theme:
      dark: darkly
      light: flatly
    css: styles.css
    toc: true
    code-copy: true
    code-overflow: wrap
    include-after-body: _includes/lang-switcher-script.html
```

**Success criteria:**
- Clicking globe button toggles dropdown
- Clicking outside dropdown closes it
- Works on both desktop and mobile

---

### Task 7: Test Switcher on Static Pages

**Actions:**

1. Render the site:
```bash
quarto render
```

2. Serve locally:
```bash
quarto preview
```

3. Test scenarios:
   - Visit `/en/about/` → Click switcher → Should go to `/fr/about/`
   - Visit `/fr/contact/` → Click switcher → Should go to `/en/contact/`
   - Visit `/en/` → Click switcher → Should go to `/fr/`
   - Visit `/en/thanks/` → Click switcher → Should go to `/fr/thanks/`

4. Check visual appearance:
   - Switcher appears in navbar (right side)
   - Switcher appears in footer (right side)
   - Dropdown opens on hover/click
   - Current language is muted in dropdown
   - Works in both dark and light themes

**Success criteria:**
- All static pages link correctly between languages
- Switcher is visually consistent across pages
- No console errors
- No broken links

---

### Phase 3 Scope Boundary

Phase 3 focuses on **static pages** (about, contact, thanks) only.
Blog posts are included only to verify **fallback behavior works safely**.

Blog posts will link to target language homepage (fallback) in Phase 3.
Actual blog post translation linking is implemented in Phase 4 when manifest exists.

### Task 8: Test Switcher on Blog Posts (Fallback Behavior)

**Actions:**

1. Visit an English blog post: `/en/blog/posts/hello-world/`
2. Click language switcher globe
3. Should see dropdown with FR and EN options
4. Click FR → Should navigate to `/fr/` (homepage fallback, since no manifest exists yet)

**Expected behavior:**
- Switcher appears and functions
- Links to French homepage (not to equivalent post, since manifest doesn't exist in Phase 3)

**Success criteria:**
- No errors
- Fallback to homepage works
- Switcher remains visible and functional

---

### Task 9: Update _quarto.yml to Load Extension

**Files to modify:**
- `_quarto.yml`

**Actions:**

Add extension reference at project level:

```yaml
project:
  type: website
  output-dir: _site
  render:
    - en/
    - fr/
    - index.html

# Load multilingual extension
extensions:
  - multilang
```

**Success criteria:**
- Build output shows no errors or warnings related to extension loading
- `{{< lang-switch >}}` renders to HTML with class "lang-switcher" in output
- Site renders with 0 build failures for extension-related issues

---

### Task 10: Verify No Broken Links

**Actions:**

1. Build site:
```bash
quarto render
```

2. Check for broken links in output directory:
```bash
# Manual check: browse key pages and verify all switcher links work
# Or use a link checker if available
```

3. Test matrix:

| From Page | To Language | Expected Target | Status |
|-----------|-------------|-----------------|--------|
| /en/ | FR | /fr/ | ✓ |
| /en/about/ | FR | /fr/about/ | ✓ |
| /en/contact/ | FR | /fr/contact/ | ✓ |
| /en/thanks/ | FR | /fr/thanks/ | ✓ |
| /fr/ | EN | /en/ | ✓ |
| /fr/about/ | EN | /en/about/ | ✓ |
| /fr/contact/ | EN | /en/contact/ | ✓ |
| /fr/thanks/ | EN | /en/thanks/ | ✓ |
| /en/blog/posts/hello-world/ | FR | /fr/ (fallback) | ✓ |

**Note:** Blog posts render to `/LANG/blog/posts/POST-SLUG/index.html` by default in Quarto.
Test paths use `/LANG/blog/posts/hello-world/` (without trailing index.html for readability).

**Success criteria:**
- All links resolve correctly
- No 404 errors
- Blog posts fallback to homepage (expected until Phase 4)

---

## Implementation Notes

### Known Limitations (Acceptable for Phase 3)

1. **Blog post equivalents:** Phase 3 does not implement manifest-based blog post linking. Fallback to homepage is intentional and safe.
2. **Shortcode in navbar:** Quarto may not support shortcodes directly in navbar config. If this fails, we'll use raw HTML with JavaScript to detect current language.
3. **CSS-only hover on mobile:** May not work on all mobile browsers. JavaScript click fallback (Task 6) addresses this.

### Phase 4 Preview

Phase 4 will:
- Build `_data/translations-manifest.json` via pre-render script
- Update `lang-switch.lua` to read manifest for blog posts
- Link to actual equivalent posts (not homepage fallback)

### Alternative Approaches Considered

1. **Plain HTML partial (not shortcode):** Cannot access Pandoc metadata like `lang`. Would require JavaScript to detect current language from URL or DOM.
2. **babelquarto:** Requires R dependency. Our Lua approach is lighter and project-native.
3. **Separate navbar per language:** Would require duplicating navbar config in `_metadata.yml` per language. Shortcode approach is more maintainable.

---

## Success Checklist

- [ ] Extension directory created with valid `_extension.yml`
- [ ] `lang-switch.lua` shortcode implemented and syntactically correct
- [ ] CSS styling added to `styles.css`
- [ ] Switcher added to navbar
- [ ] Switcher added to footer
- [ ] JavaScript fallback script created (optional but recommended)
- [ ] Extension loaded in `_quarto.yml`
- [ ] Site renders without errors
- [ ] Static pages link correctly between languages
- [ ] Blog posts fallback to homepage (expected)
- [ ] No broken links
- [ ] Visual appearance consistent in dark and light themes
- [ ] Dropdown works on hover and click

---

## Rollback Plan

If Phase 3 breaks the build:

1. Remove extension reference from `_quarto.yml`:
   ```yaml
   # extensions:
   #   - multilang
   ```

2. Remove shortcode calls from navbar and footer (`_quarto.yml`)

3. Delete `_extensions/multilang/` directory (if created)

4. Rebuild:
   ```bash
   quarto render
   ```

Site will render without language switcher but remain functional.

If navbar/footer integration uses raw HTML fallback before achieving working shortcode:
1. Delete custom HTML files created as fallback (`_includes/navbar-custom.html`, `_includes/footer-lang-switcher.html`)
2. Revert navbar and footer config in `_quarto.yml` to original state
3. Complete steps 1-4 above

---

## Next Steps (Phase 4)

After Phase 3 is complete and verified:
- Implement `scripts/build-manifest.py` to scan blog posts
- Add `translation` field to blog post frontmatter
- Update `lang-switch.lua` to read manifest for blog posts
- Implement machine-translation banner (`translation-banner.lua`)
