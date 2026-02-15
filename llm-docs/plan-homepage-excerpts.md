# Plan: Homepage Blog Post Excerpts

## Goal

Replace the current metadata-only listing on the homepage with Antirez-style article previews showing the first ~200 words of each post, plus a "Read more" link.

## Current State

- Homepage (`en/index.qmd`, `fr/index.qmd`) uses Quarto's built-in `listing:` with `type: default`
- Shows `fields: [date, title, description]` — no actual article content
- Two-column layout (main + sidebar) stays as-is

## Approach: Lua Filter

A new Lua filter (`_extensions/multilang/blog-excerpts.lua`) that:
1. Detects the homepage by looking for a `:::{.blog-excerpts}` div
2. Reads blog post `.qmd` files from the filesystem
3. Parses YAML frontmatter (title, date, categories, draft) and content
4. Truncates content at ~200 words at the AST level (using `pandoc.read()` so markdown formatting is preserved)
5. Generates HTML blocks for each post (title, date, excerpt, "read more" link)
6. Replaces the `:::{.blog-excerpts}` div with the generated listing

### Why Lua filter over alternatives?
- **vs. pre-render script**: no intermediate files, no build step to maintain
- **vs. manual `abstract` field**: no content duplication, works automatically for new posts
- **vs. custom EJS template**: EJS templates can't access post body content, only frontmatter
- **Precedent**: project already has 3 Lua filters in `_extensions/multilang/`

## Files to Change

### 1. New: `_extensions/multilang/blog-excerpts.lua`

The Lua filter with these responsibilities:

**Post discovery:**
- Use `quarto.project.directory` to get the project root (reliable across execution contexts)
- Determine language from document metadata (`lang` field) or fall back to scanning the file path for `/en/` or `/fr/`
- Scan `{project_root}/{lang}/blog/posts/*/index.qmd` for post files
- Skip posts with `draft: true`

**Parsing (frontmatter + content):**
- Read each `.qmd` file, pass the entire content to `pandoc.read(content, "markdown")`
- This returns a Pandoc document with both `meta` (frontmatter) and `blocks` (content) — no regex/pattern matching needed
- Extract title, date, draft status, categories from `doc.meta`

**Excerpt generation:**
- From the parsed AST blocks, strip leading `.callout-note` divs (translation banners)
- Strip images/figures from excerpt blocks (they'd break layout)
- Strip footnote references (definitions may be outside the excerpt)
- Walk remaining blocks counting words; truncate at ~200 words on a block boundary (end of paragraph/list item)
- If truncated, append "..." indicator

**HTML generation for each post:**
```html
<article class="excerpt-item">
  <h3 class="excerpt-title"><a href="blog/posts/{dir}/">Post Title</a></h3>
  <div class="excerpt-meta">
    <time>15 Feb, 2026</time>
  </div>
  <div class="excerpt-content">
    <!-- rendered markdown excerpt here -->
  </div>
  <a href="blog/posts/{dir}/" class="excerpt-readmore">Read more →</a>
</article>
```

**Sorting:** by date descending (newest first)

**Max items:** 10 (matching current listing config)

### 2. Modify: `en/index.qmd` and `fr/index.qmd`

Remove the `listing:` YAML config. Replace `:::{#recent-posts}:::` with `:::{.blog-excerpts}:::`.

Before:
```yaml
listing:
  id: recent-posts
  contents: blog/posts
  sort: "date desc"
  type: default
  max-items: 10
  date-format: "D MMM, YYYY"
  fields: [date, title, description]
```

After: (no listing config)

Body change:
```markdown
::: {.blog-excerpts}
:::
```

The "View all posts" / "Voir tous les articles" link stays below the div.

### 3. Modify: `_extensions/multilang/_extension.yml`

Register the new filter in the extension (consistent with how `hreflang.lua` and `translation-banner.lua` are registered):
```yaml
contributes:
  filters:
    - translation-banner.lua
    - hreflang.lua
    - blog-excerpts.lua
```

No changes to `_quarto.yml` — the extension handles filter registration.

### 4. Modify: `styles.css`

Add excerpt styling:

```css
/* ===== BLOG EXCERPT LISTING ===== */

.excerpt-item {
  margin-bottom: 2rem;
  padding-bottom: 2rem;
  border-bottom: 1px solid var(--bs-border-color);
}

.excerpt-item:last-child {
  border-bottom: none;
}

.excerpt-title {
  font-size: 1.3rem;
  font-weight: 600;
  margin-bottom: 0.25rem;
}

.excerpt-title a {
  color: var(--bs-heading-color, var(--bs-body-color));
}

.excerpt-meta {
  font-size: 0.85rem;
  color: var(--bs-secondary-color);
  margin-bottom: 0.75rem;
}

.excerpt-content {
  margin-bottom: 0.75rem;
}

.excerpt-content p:last-child {
  margin-bottom: 0;
}

.excerpt-readmore {
  font-size: 0.9rem;
  font-weight: 500;
}
```

## Edge Cases

- **Draft posts**: Skipped (check `draft: true` in frontmatter)
- **Posts with no content after frontmatter**: Show title/date only, no excerpt
- **Short posts (<200 words)**: Show full content, still show "Read more" link (keeps code simple)
- **Quarto shortcodes in post content** (e.g., `{{< include >}}`): Won't be expanded in excerpt — acceptable since they're rare in opening paragraphs
- **Translation callout blocks**: Strip leading `.callout-note` divs from excerpt (translation banners, not content)
- **Images/figures in excerpt**: Stripped to avoid layout issues
- **Footnotes in excerpt**: Footnote references stripped (definitions may be outside the excerpt range)
- **Zero posts**: Show nothing (empty div)

## Branch & PR

- Feature branch: `feature/homepage-excerpts`
- PR against `main` when complete

## Testing

1. `quarto preview` and visually inspect the homepage in both EN and FR
2. Verify excerpts show rendered markdown (links, emphasis, lists)
3. Verify "Read more" links go to the right post
4. Verify draft posts are excluded
5. Check responsive layout (sidebar below on mobile)
6. Check both light and dark themes
