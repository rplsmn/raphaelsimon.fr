---
name: maintaining-quarto-website
description: Use when working on Quarto static websites - covers project structure, content creation, theming, blog posts, navigation, search, contact forms, and deployment to Cloudflare Pages.
---

# Maintaining a Quarto Website

This skill covers the essential patterns and strategies for maintaining a Quarto static website with a blog, about page, contact form, and search functionality.

## Project Structure

A Quarto website has this structure:

```
project-root/
├── _quarto.yml           # Main project configuration
├── _variables.yml        # Reusable variables (optional)
├── index.qmd             # Homepage/landing page
├── about.qmd             # About page
├── contact.qmd           # Contact page
├── blog/                 # Blog directory
│   ├── index.qmd         # Blog listing page
│   ├── _metadata.yml     # Shared post options
│   └── posts/            # Blog posts directory
│       └── YYYY-MM-DD-slug/
│           ├── index.qmd # Post content
│           └── images/   # Post-specific images (optional)
├── styles.css            # Custom CSS
├── custom.scss           # SCSS theme overrides (optional)
├── _includes/            # HTML partials (contact forms, etc.)
│   └── contact-form.html
├── images/               # Site-wide images
│   └── profile.jpg
└── _site/                # Generated output (gitignored)
```

## Key Files

### _quarto.yml - Project Configuration

This is the central configuration file controlling all aspects of the website:

```yaml
project:
  type: website
  output-dir: _site

website:
  title: "Site Title"
  description: "Site description for SEO"
  site-url: https://example.com
  favicon: images/favicon.ico

  # Search (enabled by default)
  search:
    location: navbar
    type: overlay
    keyboard-shortcut: ["?", "/"]

  # Navigation
  navbar:
    background: dark
    left:
      - text: Home
        href: index.qmd
      - text: Blog
        href: blog/index.qmd
      - text: About
        href: about.qmd
      - text: Contact
        href: contact.qmd
    right:
      - icon: github
        href: https://github.com/username
      - icon: rss
        href: blog/index.xml

  # Footer
  page-footer:
    left: "Copyright 2024"
    right:
      - icon: github
        href: https://github.com/username

# Dark/Light theme
format:
  html:
    theme:
      light: flatly
      dark: darkly
    css: styles.css
    toc: true

# Language
lang: en
```

### Homepage with Latest Posts (index.qmd)

To show recent blog posts on the landing page:

```yaml
---
title: "Welcome"
listing:
  id: recent-posts
  contents: blog/posts
  sort: "date desc"
  type: grid
  max-items: 3
  grid-columns: 3
  categories: false
  fields: [image, date, title, description]
---

Welcome to my website!

## Latest Posts

::: {#recent-posts}
:::
```

### Blog Listing Page (blog/index.qmd)

```yaml
---
title: "Blog"
listing:
  contents: posts
  sort: "date desc"
  type: default
  categories: true
  feed: true
---
```

### Blog Post Template (blog/posts/YYYY-MM-DD-slug/index.qmd)

```yaml
---
title: "Post Title"
description: "Brief description for listings and SEO"
author: "Author Name"
date: "2024-01-15"
categories: [category1, category2]
image: thumbnail.jpg
draft: false
---

Post content here...
```

### About Page (about.qmd)

```yaml
---
title: "About Me"
image: images/profile.jpg
about:
  template: trestles
  image-shape: round
  image-width: 10em
  links:
    - icon: github
      text: GitHub
      href: https://github.com/username
    - icon: linkedin
      text: LinkedIn
      href: https://linkedin.com/in/username
    - icon: envelope
      text: Email
      href: mailto:email@example.com
---

Bio content here...
```

Available about templates: `jolla`, `trestles`, `solana`, `marquee`, `broadside`

### Contact Page with Form (contact.qmd)

For static sites, use Web3Forms or Formspree:

```yaml
---
title: "Contact"
include-after-body:
  - _includes/contact-form.html
---

Get in touch using the form below.
```

**_includes/contact-form.html**:

```html
<form action="https://api.web3forms.com/submit" method="POST" class="contact-form">
  <input type="hidden" name="access_key" value="YOUR_ACCESS_KEY_HERE">
  <input type="hidden" name="subject" value="New Contact from Website">
  <input type="hidden" name="redirect" value="https://yoursite.com/thanks.html">
  <input type="checkbox" name="botcheck" style="display: none;">

  <div class="mb-3">
    <label for="name" class="form-label">Name</label>
    <input type="text" name="name" id="name" class="form-control" required>
  </div>

  <div class="mb-3">
    <label for="email" class="form-label">Email</label>
    <input type="email" name="email" id="email" class="form-control" required>
  </div>

  <div class="mb-3">
    <label for="message" class="form-label">Message</label>
    <textarea name="message" id="message" class="form-control" rows="5" required></textarea>
  </div>

  <!-- Optional: hCaptcha spam protection -->
  <div class="h-captcha mb-3" data-captcha="true"></div>
  <script src="https://web3forms.com/client/script.js" async defer></script>

  <button type="submit" class="btn btn-primary">Send Message</button>
</form>
```

## Common Tasks

### Creating a New Blog Post

1. Create directory: `blog/posts/YYYY-MM-DD-descriptive-slug/`
2. Create `index.qmd` with frontmatter (title, description, author, date, categories)
3. Add optional `thumbnail.jpg` for listings
4. Write content in markdown
5. Preview with `quarto preview`

### Adding Navigation Items

Edit `website.navbar` in `_quarto.yml`:

```yaml
navbar:
  left:
    - text: "New Page"
      href: new-page.qmd
    - text: "Dropdown"
      menu:
        - text: "Item 1"
          href: item1.qmd
        - text: "Item 2"
          href: item2.qmd
```

### Customizing Themes

**Method 1: Simple CSS overrides** (styles.css):

```css
/* Override specific elements */
.navbar { background-color: #1a1a2e !important; }
h1, h2, h3 { color: #16213e; }
```

**Method 2: SCSS theme layer** (custom.scss):

```scss
/*-- scss:defaults --*/
$primary: #0066cc;
$body-bg: #ffffff;
$body-color: #333333;
$link-color: #0066cc;
$navbar-bg: #1a1a2e;

/*-- scss:rules --*/
.navbar-brand {
  font-weight: 700;
}
```

Then reference in `_quarto.yml`:

```yaml
format:
  html:
    theme:
      light: [flatly, custom.scss]
      dark: [darkly, custom-dark.scss]
```

### Adding Custom JavaScript

**Method 1: Include file**

```yaml
format:
  html:
    include-after-body:
      - scripts/custom.js
```

**Method 2: Inline in config**

```yaml
format:
  html:
    include-in-header:
      - text: |
          <script>
            console.log('Custom JS loaded');
          </script>
```

### Adding Lua Filters

Create `_extensions/filter-name/filter-name.lua`:

```lua
function Div(el)
  if el.classes:includes("special") then
    -- Transform the div
    return el
  end
end
```

Reference in `_quarto.yml`:

```yaml
filters:
  - _extensions/filter-name/filter-name.lua
```

### Enabling RSS Feed

In `blog/index.qmd`:

```yaml
listing:
  feed: true
```

Ensure `site-url` is set in `_quarto.yml` for valid feed URLs.

### Adding Categories

In blog posts, add categories in frontmatter:

```yaml
categories: [technology, tutorial, python]
```

Enable category sidebar in listing:

```yaml
listing:
  categories: true  # or: numbered, unnumbered, cloud
```

### Multilingual Content

Set default language in `_quarto.yml`:

```yaml
lang: fr
```

Override UI strings:

```yaml
language:
  toc-title-document: "Table des matières"
  search-placeholder: "Rechercher..."
```

## Deployment to Cloudflare Pages

### Method 1: Direct Upload

1. Run `quarto render` locally
2. Upload `_site/` directory to Cloudflare Pages

### Method 2: Git Integration (Recommended)

1. Push rendered site to git (or use CI to render)
2. Connect Cloudflare Pages to your repository
3. Configure:
   - **Build command**: `exit 0` (pre-rendered) or install Quarto in CI
   - **Build output directory**: `_site`
   - **Root directory**: `/` (or subdirectory if applicable)

### GitHub Actions for Cloudflare Pages

```yaml
# .github/workflows/deploy.yml
name: Deploy to Cloudflare Pages

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Quarto
        uses: quarto-dev/quarto-actions/setup@v2

      - name: Render
        run: quarto render

      - name: Deploy to Cloudflare Pages
        uses: cloudflare/pages-action@v1
        with:
          apiToken: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          accountId: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
          projectName: your-project-name
          directory: _site
```

### Custom Domain Setup

1. In Cloudflare Pages dashboard, go to Custom Domains
2. Add your domain (e.g., example.com)
3. Update DNS (A or CNAME records) as instructed
4. Wait for SSL certificate provisioning

## Troubleshooting

### Changes Not Appearing

- Global config changes require full re-render: `quarto render` (not just preview)
- Clear browser cache or use incognito mode
- Check `_site/` directory contains updated files

### Build Failures

- Validate `_quarto.yml` syntax (YAML is whitespace-sensitive)
- Check for missing referenced files (images, includes)
- Verify all `.qmd` files have valid frontmatter

### Search Not Working

- Ensure `search: true` or search configuration exists in `_quarto.yml`
- Search index is built during render, not preview
- Check browser console for JavaScript errors

### Images Not Loading

- Use relative paths from the document location
- For blog posts, place images in the post directory
- For site-wide images, use paths from project root: `/images/photo.jpg`

### RSS Feed Invalid

- Must have `site-url` set in `_quarto.yml`
- Validate with an RSS validator
- Check that blog posts have valid dates

## Commands Reference

| Command | Purpose |
|---------|---------|
| `quarto create project website` | Create new website project |
| `quarto create project blog` | Create new blog project |
| `quarto preview` | Live preview with hot reload |
| `quarto render` | Full site render to `_site/` |
| `quarto render --to html` | Render HTML only |
| `quarto check` | Verify Quarto installation |
| `quarto add extension-name` | Install extension |

## Best Practices

1. **Use drafts**: Set `draft: true` in post frontmatter during writing
2. **Consistent naming**: Use `YYYY-MM-DD-slug` for post directories
3. **Optimize images**: Compress images before adding to repo
4. **Test locally**: Always `quarto preview` before committing
5. **Version control**: Keep `_site/` in `.gitignore` (render in CI)
6. **Backup config**: Comment your `_quarto.yml` for future reference
