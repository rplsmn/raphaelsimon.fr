# Quarto Website Setup Guide for raphaelsimon.fr

This guide covers setting up a personal website with Quarto, deployed to Cloudflare Pages.

## Prerequisites

- Git installed and configured
- Quarto CLI installed (`quarto check` to verify)
- Cloudflare account with domain configured
- Web3Forms account (for contact form)

## Phase 1: Project Initialization

### 1.1 Create Quarto Website Project

```bash
# Navigate to repository
cd /home/raph/Documents/sandbox/raphaelsimon.fr

# Initialize Quarto website (creates starter files)
quarto create project website .
```

This creates:

- `_quarto.yml` - Project configuration
- `index.qmd` - Homepage
- `about.qmd` - About page
- `styles.css` - Custom styles

### 1.2 Initial Project Structure

Create the full directory structure:

```bash
mkdir -p blog/posts
mkdir -p images
mkdir -p _includes
touch blog/index.qmd
touch blog/_metadata.yml
touch contact.qmd
```

Target structure:

```
raphaelsimon.fr/
├── _quarto.yml
├── index.qmd
├── about.qmd
├── contact.qmd
├── styles.css
├── blog/
│   ├── index.qmd
│   ├── _metadata.yml
│   └── posts/
├── images/
│   └── (profile.jpg, favicon.ico)
├── _includes/
│   └── contact-form.html
└── _site/              (generated, gitignored)
```

### 1.3 Update .gitignore

```gitignore
# Quarto
/.quarto/
/_site/
/_freeze/

# OS
.DS_Store
Thumbs.db

# Editor
*.swp
*~

# Secrets (if any local testing)
.env
```

## Phase 2: Core Configuration

### 2.1 Main Configuration (_quarto.yml)

```yaml
project:
  type: website
  output-dir: _site

website:
  title: "Raphaël Simon"
  description: "Personal website - Medicine, Public Health, Software Engineering, Data Science"
  site-url: https://raphaelsimon.fr
  favicon: images/favicon.ico

  # Search functionality
  search:
    location: navbar
    type: overlay
    keyboard-shortcut: ["?", "/", "k"]

  # Top navigation
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

  # Footer
  page-footer:
    left: |
      © 2026 Raphaël Simon
    right:
      - icon: github
        href: https://github.com/rplsmn
      - icon: envelope
        href: mailto:contact@raphaelsimon.fr

  # Enable back-to-top button
  back-to-top-navigation: true

# Theme with dark mode default
format:
  html:
    theme:
      dark: darkly
      light: flatly
    css: styles.css
    toc: true
    code-copy: true
    code-overflow: wrap

# Default language
lang: en

# Analytics (optional - add when ready)
# google-analytics: "G-XXXXXXXXXX"
```

### 2.2 Blog Shared Options (blog/_metadata.yml)

```yaml
# Shared options for all blog posts
freeze: true
author: "Raphaël Simon"

# Default post format
format:
  html:
    code-fold: true
    code-tools: true
```

## Phase 3: Content Pages

### 3.1 Homepage (index.qmd)

```yaml
---
title: "Raphaël Simon"
subtitle: "Consulting · Writing · Complex Problems"
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

Welcome to my personal website.

I work at the intersection of medicine, public health, software engineering, and data science. I consult on complex interdisciplinary problems and write about topics that interest me.

## Latest Posts

::: {#recent-posts}
:::

[View all posts →](blog/index.qmd)
```

### 3.2 Blog Listing Page (blog/index.qmd)

```yaml
---
title: "Blog"
listing:
  contents: posts
  sort: "date desc"
  type: default
  categories: true
  feed: true
  page-size: 10
---
```

### 3.3 About Page (about.qmd)

```yaml
---
title: "About"
image: images/profile.jpg
about:
  template: trestles
  image-shape: round
  image-width: 12em
  links:
    - icon: github
      text: GitHub
      href: https://github.com/rplsmn
    - icon: linkedin
      text: LinkedIn
      href: https://linkedin.com/in/raphael-simon-md
    - icon: envelope
      text: Email
      href: mailto:contact@raphaelsimon.fr
---

## Bio

[Write your bio here - background, expertise, interests]

## Expertise

- Medicine & Public Health
- Software Engineering
- Data Science
- Complex Systems

## Consulting

I help organizations tackle niche and complex interdisciplinary problems. If you have a challenging project that doesn't fit neatly into traditional categories, [let's talk](contact.qmd).
```

### 3.4 Contact Page (contact.qmd)

```yaml
---
title: "Contact"
include-after-body:
  - _includes/contact-form.html
---

Have a question, project idea, or just want to connect? Fill out the form below and I'll get back to you.

You can also reach me directly at [contact@raphaelsimon.fr](mailto:contact@raphaelsimon.fr).
```

### 3.5 Contact Form HTML (_includes/contact-form.html)

First, get a Web3Forms access key:

1. Go to <https://web3forms.com>
2. Click "Create Access Key"
3. Enter your email (<contact@raphaelsimon.fr>)
4. Check email for access key

Then create the form:

```html
<form action="https://api.web3forms.com/submit" method="POST" class="contact-form mt-4">
  <!-- Replace YOUR_ACCESS_KEY with actual key from Web3Forms -->
  <input type="hidden" name="access_key" value="YOUR_ACCESS_KEY">
  <input type="hidden" name="subject" value="New message from raphaelsimon.fr">
  <input type="hidden" name="from_name" value="raphaelsimon.fr Contact Form">
  <input type="checkbox" name="botcheck" style="display: none;">

  <div class="mb-3">
    <label for="name" class="form-label">Name *</label>
    <input type="text" name="name" id="name" class="form-control" placeholder="Your name" required>
  </div>

  <div class="mb-3">
    <label for="email" class="form-label">Email *</label>
    <input type="email" name="email" id="email" class="form-control" placeholder="your@email.com" required>
  </div>

  <div class="mb-3">
    <label for="subject" class="form-label">Subject</label>
    <input type="text" name="form_subject" id="subject" class="form-control" placeholder="What's this about?">
  </div>

  <div class="mb-3">
    <label for="message" class="form-label">Message *</label>
    <textarea name="message" id="message" class="form-control" rows="6" placeholder="Your message..." required></textarea>
  </div>

  <!-- hCaptcha spam protection (no config needed with Web3Forms) -->
  <div class="h-captcha mb-3" data-captcha="true"></div>
  <script src="https://web3forms.com/client/script.js" async defer></script>

  <button type="submit" class="btn btn-primary">
    Send Message
  </button>
</form>

<style>
.contact-form {
  max-width: 600px;
}
.contact-form .form-control {
  background-color: var(--bs-body-bg);
  border-color: var(--bs-border-color);
  color: var(--bs-body-color);
}
.contact-form .form-control:focus {
  border-color: var(--bs-primary);
  box-shadow: 0 0 0 0.25rem rgba(var(--bs-primary-rgb), 0.25);
}
</style>
```

### 3.6 Thank You Page (thanks.qmd)

```yaml
---
title: "Thank You"
search: false
---

Your message has been sent successfully!

I'll get back to you as soon as possible.

[← Back to Home](index.qmd)
```

Update the contact form redirect:

```html
<input type="hidden" name="redirect" value="https://raphaelsimon.fr/thanks.html">
```

## Phase 4: Sample Blog Post

### 4.1 Create First Post

```bash
mkdir -p blog/posts/2024-01-15-hello-world
```

Create `blog/posts/2024-01-15-hello-world/index.qmd`:

```yaml
---
title: "Hello World"
description: "Welcome to my new blog - what to expect and why I'm writing."
author: "Raphaël Simon"
date: "2026-02-03"
categories: [meta, welcome]
image: thumbnail.jpg
draft: false
---

Welcome to my blog! This is where I'll share thoughts on medicine, public health, software engineering, data science, and the interesting problems that emerge at their intersections.

## What to Expect

Topics will vary widely - that's by design. I'm interested in:

- **Medicine & Public Health**: Clinical insights, health systems, epidemiology
- **Software Engineering**: Architecture, best practices, tools
- **Data Science**: Analysis methods, visualization, ML applications
- **Complex Systems**: Where these fields collide

## Why Write?

Writing clarifies thinking. By explaining ideas publicly, I'm forced to refine them.

Stay tuned for more.
```

Add a placeholder thumbnail or use an existing image.

## Phase 5: Custom Styling

### 5.1 Basic Styles (styles.css)

```css
/* Custom styles for raphaelsimon.fr */

/* Improve readability */
body {
  font-size: 1.1rem;
  line-height: 1.7;
}

/* Homepage hero section */
.quarto-title-block {
  margin-bottom: 2rem;
}

/* Blog post cards */
.quarto-grid-item {
  border-radius: 8px;
  transition: transform 0.2s ease;
}

.quarto-grid-item:hover {
  transform: translateY(-2px);
}

/* Code blocks */
pre {
  border-radius: 6px;
}

/* Links */
a {
  text-decoration: none;
}

a:hover {
  text-decoration: underline;
}

/* Footer spacing */
.page-footer {
  margin-top: 3rem;
  padding-top: 1.5rem;
}

/* Contact form styling handled in contact-form.html */
```

## Phase 6: Local Testing

### 6.1 Preview Site

```bash
quarto preview
```

This starts a local server (typically <http://localhost:4200>) with hot reload.

### 6.2 Full Render

```bash
quarto render
```

Check `_site/` directory for generated files.

### 6.3 Verify Checklist

- [ ] Homepage loads with navigation
- [ ] Latest posts appear on homepage
- [ ] Blog listing shows all posts
- [ ] Blog post pages render correctly
- [ ] About page displays profile image and links
- [ ] Contact form appears and submits
- [ ] Search works (Ctrl+K or /)
- [ ] Dark/light mode toggle works
- [ ] RSS feed validates (blog/index.xml)
- [ ] All links work

## Phase 7: Cloudflare Pages Deployment

### 7.1 Cloudflare Account Setup

1. Log in to Cloudflare dashboard
2. Ensure raphaelsimon.fr domain is configured
3. Go to **Workers & Pages** > **Pages**

### 7.2 Method A: Manual Upload (Quick Start)

1. Run `quarto render` locally
2. In Cloudflare Pages, click **Create application** > **Pages** > **Upload assets**
3. Name project: `raphaelsimon-fr`
4. Upload contents of `_site/` directory
5. Deploy

### 7.3 Method B: Git Integration (Recommended)

#### Option 1: Pre-rendered (Simple)

1. Commit `_site/` to repository (remove from .gitignore)
2. Connect repository to Cloudflare Pages
3. Configure:
   - **Production branch**: `main`
   - **Build command**: `exit 0`
   - **Build output directory**: `_site`

#### Option 2: Build on Cloudflare (CI-based)

Cloudflare doesn't have Quarto pre-installed. Use GitHub Actions instead:

**.github/workflows/deploy.yml**:

```yaml
name: Deploy to Cloudflare Pages

on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      deployments: write

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Quarto
        uses: quarto-dev/quarto-actions/setup@v2

      - name: Render site
        run: quarto render

      - name: Deploy to Cloudflare Pages
        uses: cloudflare/pages-action@v1
        with:
          apiToken: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          accountId: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
          projectName: raphaelsimon-fr
          directory: _site
          gitHubToken: ${{ secrets.GITHUB_TOKEN }}
```

#### Set Up Secrets

1. Create Cloudflare API token:
   - Go to Cloudflare dashboard > My Profile > API Tokens
   - Create token with "Cloudflare Pages: Edit" permission
2. Get Account ID from Cloudflare dashboard URL
3. Add secrets to GitHub repository:
   - `CLOUDFLARE_API_TOKEN`
   - `CLOUDFLARE_ACCOUNT_ID`

### 7.4 Custom Domain Configuration

1. In Cloudflare Pages project settings, go to **Custom domains**
2. Add `raphaelsimon.fr`
3. Add `www.raphaelsimon.fr` (optional, for redirect)
4. DNS records are auto-configured since domain is on Cloudflare

### 7.5 Verify Deployment

- [ ] Site accessible at <https://raphaelsimon.fr>
- [ ] HTTPS working (automatic with Cloudflare)
- [ ] All pages load correctly
- [ ] Contact form submits successfully
- [ ] Search index works

## Phase 8: Ongoing Maintenance

### Adding New Blog Posts

```bash
# Create post directory
mkdir -p blog/posts/YYYY-MM-DD-post-slug

# Create post file
# Edit blog/posts/YYYY-MM-DD-post-slug/index.qmd

# Preview
quarto preview

# Commit and push (triggers deployment)
git add .
git commit -m "Add post: Post Title"
git push
```

### Updating Configuration

Changes to `_quarto.yml` require full re-render:

```bash
quarto render
```

### Testing Changes

Always preview before deploying:

```bash
quarto preview
```

## Quick Reference

| Task | Command |
|------|---------|
| Start preview | `quarto preview` |
| Full render | `quarto render` |
| Create new post | `mkdir blog/posts/YYYY-MM-DD-slug && touch blog/posts/YYYY-MM-DD-slug/index.qmd` |
| Check installation | `quarto check` |
| Update Quarto | `quarto update` |

## Troubleshooting

**Preview not updating**: Stop and restart `quarto preview`

**Build fails**: Check YAML syntax in `_quarto.yml` and post frontmatter

**Contact form not working**: Verify Web3Forms access key is correct

**Search not finding content**: Run full `quarto render`, search index builds on render only

**Dark mode not switching**: Clear browser cache, check theme configuration

**RSS feed errors**: Ensure `site-url` is set in `_quarto.yml`

## Resources

- [Quarto Websites Documentation](https://quarto.org/docs/websites/)
- [Quarto Blog Documentation](https://quarto.org/docs/websites/website-blog.html)
- [Web3Forms Documentation](https://docs.web3forms.com)
- [Cloudflare Pages Documentation](https://developers.cloudflare.com/pages/)
- [Bootswatch Themes](https://bootswatch.com/)
