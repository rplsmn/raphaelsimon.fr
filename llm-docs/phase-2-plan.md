# Phase 2 Implementation Plan: Content Translation

**Phase:** 2 of 5  
**Objective:** Translate core static pages to French with proper UI localization  
**Scope:** `fr/about.qmd`, `fr/contact.qmd`, `fr/index.qmd`, `fr/thanks.qmd`, contact form labels  
**Prerequisites:** Phase 1 (Structure) complete — `/en/` and `/fr/` directories exist with `_metadata.yml` configured  

---

## Overview

Phase 2 focuses exclusively on content translation. No infrastructure changes required — Quarto's built-in `_language.yml` system handles UI strings automatically when `lang: fr` is set in `fr/_metadata.yml`.

**What gets translated:**
- French page content (about, contact, homepage, thanks)
- Contact form labels and placeholders (in a French-specific include file)
- Form redirect URL (point to `/fr/thanks.html`)

**What Quarto handles automatically:**
- Search interface labels ("Search...", "No results")
- TOC labels ("On this page" → "Sur cette page")
- Listing pagination ("Next", "Previous")
- Browser-native form validation messages (auto-localize based on `<html lang="fr">`)

---

## Pre-flight Verification

### Task 1: Verify Phase 1 completion
**Action:**
```bash
cd /home/rsimon/repos/raphaelsimon.fr
ls -la en/ fr/
cat en/_metadata.yml
cat fr/_metadata.yml
ls -la en/blog/posts/ fr/blog/posts/
```

**Success criteria:**
- Both `en/` and `fr/` directories exist
- Each contains: `_metadata.yml`, `about.qmd`, `contact.qmd`, `index.qmd`, `thanks.qmd`, `blog/`
- Each `blog/` contains `posts/` subdirectory
- `en/_metadata.yml` has `lang: en`
- `fr/_metadata.yml` has `lang: fr`

**Rollback:** If Phase 1 incomplete, stop and complete Phase 1 first.

---

## Content Translation Tasks

### Task 2a: Verify and fix English contact form configuration
**File:** `/home/rsimon/repos/raphaelsimon.fr/_includes/contact-form-en.html`

**Action:** The current setup uses a shared `contact-form.html` file. This must be split into language-specific includes.

1. Create English version: Copy the existing `contact-form.html` to `contact-form-en.html`
2. Update the redirect URL in `contact-form-en.html` from `/thanks.html` to `/en/thanks.html`
3. Update `en/contact.qmd` to reference `contact-form-en.html` instead of `contact-form.html`

**Command to copy existing form:**
```bash
cp /home/rsimon/repos/raphaelsimon.fr/_includes/contact-form.html /home/rsimon/repos/raphaelsimon.fr/_includes/contact-form-en.html
```

**Then edit `contact-form-en.html`:**
- Line 6: Change `redirect` from `https://raphaelsimon.fr/thanks.html` to `https://raphaelsimon.fr/en/thanks.html`

**Then update `en/contact.qmd`:**
- Change include path from `../_includes/contact-form.html` to `../_includes/contact-form-en.html`

**Success criteria:**
- `contact-form-en.html` exists with English labels and `/en/thanks.html` redirect
- `en/contact.qmd` references `contact-form-en.html`

---

### Task 2: Translate `fr/about.qmd`
**File:** `/home/rsimon/repos/raphaelsimon.fr/fr/about.qmd`

**Action:** Replace English content with French translation. Keep frontmatter structure identical (title can be translated, but field names stay English).

**French content:**
```markdown
---
title: "À propos"
image: images/profile.jpeg
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
    - icon: bluesky
      text: Bluesky
      href: https://bsky.app/profile/raphsmn.bsky.social
    - icon: envelope
      text: Email
      href: mailto:contact@raphaelsimon.fr
---

## Biographie

Médecin devenu ingénieur. J'ai été formé en médecine, raté la porte de la radiologie, et franchi une autre — vers la santé publique, l'informatique médicale, et finalement le logiciel. Aujourd'hui je construis des choses et réfléchis à la façon dont la technologie façonne les politiques (et vice versa).

Je suis attiré par les problèmes qui ne rentrent pas proprement dans un seul domaine. Plus l'intersection est floue, plus c'est intéressant.

Basé en France. Plusieurs langues parlées couramment, d'autres en cours d'apprentissage.

## Expertise

- Médecine et Santé Publique
- Ingénierie Logicielle
- Science des Données
- Systèmes Complexes

## Conseil

J'aide les organisations à résoudre des problèmes interdisciplinaires complexes et de niche. Si vous avez un projet difficile qui ne rentre pas dans les catégories traditionnelles, [discutons-en](contact.qmd).
```

**Success criteria:**
- File saved with UTF-8 encoding
- All prose content in French
- Link to `contact.qmd` remains relative (correct path)
- Frontmatter structure matches English version

---

### Task 4: Create French contact form include
**File:** `/home/rsimon/repos/raphaelsimon.fr/_includes/contact-form-fr.html`

**Action:** Create French version of contact form with translated labels and French redirect URL.

**Note on approach:** The macro plan says "Contact form labels — Put directly in each `contact.qmd` file (separate files anyway)", meaning contact pages are language-specific files. This implementation uses separate include files (`contact-form-en.html`, `contact-form-fr.html`) for the form HTML/styling, which honors that principle while keeping form markup (HTML) separate from page content (Markdown) — a best practice for maintainability.

**French form content:**
```html
<form action="https://api.web3forms.com/submit" method="POST" class="contact-form mt-4">
  <!-- Replace YOUR_ACCESS_KEY with actual key from Web3Forms -->
  <input type="hidden" name="access_key" value="d7a107cb-6de6-4a38-a129-6f9af76972e2">
  <input type="hidden" name="subject" value="Nouveau message depuis raphaelsimon.fr">
  <input type="hidden" name="from_name" value="raphaelsimon.fr Formulaire de Contact">
  <input type="hidden" name="redirect" value="https://raphaelsimon.fr/fr/thanks.html">
  <input type="checkbox" name="botcheck" style="display: none;">

  <div class="mb-3">
    <label for="name" class="form-label">Nom *</label>
    <input type="text" name="name" id="name" class="form-control" placeholder="Votre nom" required>
  </div>

  <div class="mb-3">
    <label for="email" class="form-label">Email *</label>
    <input type="email" name="email" id="email" class="form-control" placeholder="votre@email.com" required>
  </div>

  <div class="mb-3">
    <label for="subject" class="form-label">Sujet</label>
    <input type="text" name="form_subject" id="subject" class="form-control" placeholder="De quoi s'agit-il ?">
  </div>

  <div class="mb-3">
    <label for="message" class="form-label">Message *</label>
    <textarea name="message" id="message" class="form-control" rows="6" placeholder="Votre message..."
      required></textarea>
  </div>

  <!-- hCaptcha spam protection (no config needed with Web3Forms) -->
  <div class="h-captcha mb-3" data-captcha="true"></div>
  <script src="https://web3forms.com/client/script.js" async defer></script>

  <button type="submit" class="btn btn-primary">
    Envoyer le Message
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

**Key differences from English version:**
- Subject line: "Nouveau message depuis raphaelsimon.fr" (French)
- From name: "raphaelsimon.fr Formulaire de Contact" (French)
- Redirect: `https://raphaelsimon.fr/fr/thanks.html` (French path)
- All labels and placeholders in French
- Button text: "Envoyer le Message" (Send Message in French)

**Success criteria:**
- File created at `/home/rsimon/repos/raphaelsimon.fr/_includes/contact-form-fr.html`
- Form redirect points to `/fr/thanks.html`
- All labels and placeholders in French
- Hidden fields use French strings
- CSS styling preserved (identical to English version)
- Access key matches English version (same Web3Forms account)

---

### Task 5: Translate `fr/contact.qmd`
**File:** `/home/rsimon/repos/raphaelsimon.fr/fr/contact.qmd`

**Action:** Replace English content with French translation and point to French form include. Also update `en/contact.qmd` to point to English form include.

**For `en/contact.qmd`:** Update the include-after-body to reference `contact-form-en.html`:
```markdown
---
title: "Contact"
include-after-body:
   - ../_includes/contact-form-en.html
---

Have a question, project idea, or just want to connect? Fill out the form below and I'll get back to you.

You can also reach me directly at [contact@raphaelsimon.fr](mailto:contact@raphaelsimon.fr).
```

**For `fr/contact.qmd`:** Replace with French version and reference `contact-form-fr.html`:
```markdown
---
title: "Contact"
include-after-body:
   - ../_includes/contact-form-fr.html
---

Vous avez une question, une idée de projet, ou vous voulez simplement échanger ? Remplissez le formulaire ci-dessous et je vous répondrai.

Vous pouvez aussi me joindre directement à [contact@raphaelsimon.fr](mailto:contact@raphaelsimon.fr).
```

**Success criteria:**
- `en/contact.qmd` points to `contact-form-en.html`
- `fr/contact.qmd` points to `contact-form-fr.html`
- Both files have correct English/French prose content
- Email links preserved

---

### Task 6: Translate `fr/index.qmd`
**File:** `/home/rsimon/repos/raphaelsimon.fr/fr/index.qmd`

**Action:** Replace English content with French translation. Keep listing configuration identical (pulls from `fr/blog/posts/` automatically).

**French content:**
```markdown
---
title: "Raphaël Simon"
pagetitle: "Raphaël Simon"
page-layout: custom
toc: false
listing:
  id: recent-posts
  contents: blog/posts
  sort: "date desc"
  type: default
  max-items: 10
  date-format: "MMM D, YYYY"
  fields: [date, title, description]
---

::: {.homepage-container}

:::: {.two-column-layout}

::: {.main-column}
## Récents

::: {#recent-posts}
:::

[Voir tous les articles →](blog/index.qmd)
:::

::: {.sidebar-column}
## Sélection

### Articles en vedette
- [Hello World](blog/posts/2026-02-02-hello-world/index.qmd)

### Projets
- [AutoPMSI](https://autopmsi.raphaelsimon.fr) - Outil d'automatisation PMSI

### À lire
- [Simon Willison's Weblog](https://simonwillison.net/)
:::

::::

:::
```

**Success criteria:**
- Frontmatter listing config unchanged
- Section headers ("Récents", "Sélection") in French
- Relative links preserved
- Sidebar content translated

**Note:** Listing will pull from `fr/blog/posts/` directory (currently empty — blog translation happens in Phase 4).

---

### Task 7: Translate `fr/thanks.qmd`
**File:** `/home/rsimon/repos/raphaelsimon.fr/fr/thanks.qmd`

**Action:** Replace English content with French translation.

**French content:**
```markdown
---
title: "Merci"
search: false
---

Votre message a été envoyé avec succès !

Je vous répondrai dès que possible.

[← Retour à l'accueil](index.qmd)
```

**Success criteria:**
- Content in French
- Relative link to homepage preserved
- `search: false` maintained

---

## Verification Tasks

### Task 8: Test render French pages
**Action:**
```bash
cd /home/rsimon/repos/raphaelsimon.fr
quarto render fr/about.qmd
quarto render fr/contact.qmd
quarto render fr/index.qmd
quarto render fr/thanks.qmd
```

**Success criteria:**
- All four commands succeed without errors
- Output files created in `_site/fr/`:
  - `_site/fr/about.html`
  - `_site/fr/contact.html`
  - `_site/fr/index.html`
  - `_site/fr/thanks.html`

**Rollback:** If render fails, check:
1. YAML frontmatter syntax (indentation, quotes)
2. File encoding (must be UTF-8)
3. Relative link paths
4. Include file path in `contact.qmd`

---

### Task 9: Full site render
**Action:**
```bash
cd /home/rsimon/repos/raphaelsimon.fr
quarto render
```

**Success criteria:**
- Render completes without errors
- Both `/en/` and `/fr/` pages generated in `_site/`
- No warnings about missing files or broken links

**Rollback:** If render fails:
1. Check console output for specific file errors
2. Verify `_quarto.yml` hasn't been modified
3. Ensure all `.qmd` files have valid frontmatter

---

### Task 10: Verify French UI strings
**Action:** Start preview server and test UI localization.

**Step 1: Start server**
```bash
cd /home/rsimon/repos/raphaelsimon.fr
quarto preview --port 4444 --no-browser
```
(Server runs in background; proceed to Step 2 while it's running)

**Step 2: Manual checks** (in separate terminal)
1. Navigate to `http://localhost:4444/fr/about.html`
2. Verify TOC title shows "Sur cette page" (not "On this page")
3. Use search (`Ctrl+K`) — verify placeholder is "Rechercher..." (not "Search...")
4. Navigate to `http://localhost:4444/fr/contact.html`
5. Verify form labels are in French
6. Test form validation (try submitting empty) — browser messages should auto-localize based on `<html lang="fr">` attribute
7. Check `<html>` tag in browser inspector: should have `lang="fr"` attribute

**Success criteria:**
- TOC and search UI strings in French
- Form labels in French
- Browser validation messages in French (or browser default language)
- HTML `lang` attribute set to `fr`

**Rollback:** If UI strings are in English:
1. Check `fr/_metadata.yml` has `lang: fr`
2. Verify Quarto version supports French (run `quarto check`)
3. Check console output for language file loading errors

---

### Task 11: Verify form redirect
**Action:** Test contact form submission and validation message localization.

**Steps:**
1. Navigate to `http://localhost:4444/fr/contact.html`
2. Verify form loads with French labels
3. Test browser validation: leave name field empty, try to submit — browser should display French validation message (e.g., "Veuillez remplir ce champ" or browser default language)
4. Fill form with test data (name, email, message)
5. Click "Envoyer le Message"
6. Complete hCaptcha if prompted
7. Submit

**Success criteria:**
- Form submits successfully
- Redirects to `/fr/thanks.html` (local preview may show localhost equivalent)
- Thanks page displays in French
- Browser validation messages are localized (French or browser language) — this auto-occurs due to `lang="fr"` attribute set by `fr/_metadata.yml`

**Rollback:** If redirect fails:
1. Check `contact-form-fr.html` redirect URL
2. Verify `fr/thanks.html` exists in `_site/`
3. Check Web3Forms dashboard for submission

---

### Task 12: Verify content accuracy
**Action:** Spot-check French translations for major errors.

**Manual checks:**
1. Read `fr/about.html` — verify prose is natural French, no machine translation artifacts
2. Read `fr/contact.html` — verify form instructions are clear
3. Read `fr/index.html` — verify sidebar content makes sense
4. Read `fr/thanks.html` — verify message is complete

**Success criteria:**
- No obvious translation errors
- No mixed-language content (English fragments in French pages)
- Links functional
- Formatting preserved

**Rollback:** If errors found:
1. Edit source `.qmd` files
2. Re-render affected pages
3. Re-verify

---

### Task 13: Clean up shared contact form
**Action:** Remove the shared `contact-form.html` to avoid accidental reuse.

```bash
cd /home/rsimon/repos/raphaelsimon.fr
rm _includes/contact-form.html
```

**Rationale:** After separating into `contact-form-en.html` and `contact-form-fr.html`, the shared file should be removed to prevent confusion or accidental reuse.

---

## Safety & Rollback

### Backup before starting
```bash
cd /home/rsimon/repos/raphaelsimon.fr
git status
git stash push -m "pre-phase-2-backup"
```

### Create checkpoint after Task 2a
```bash
git add _includes/contact-form-en.html
git commit -m "Phase 2: Create English contact form include (split from shared form)"
```

### Create checkpoint after Task 3
```bash
git add _includes/contact-form-fr.html
git commit -m "Phase 2: Add French contact form include"
```

### Create checkpoint after language-specific contact files
```bash
git add en/contact.qmd fr/contact.qmd
git commit -m "Phase 2: Update contact pages to use language-specific form includes"
```

### Create checkpoint after all translations
```bash
git add fr/*.qmd
git commit -m "Phase 2: Translate French content (about, contact, index, thanks)"
```

### Create checkpoint after cleanup
```bash
git rm _includes/contact-form.html
git commit -m "Phase 2: Remove shared contact form (replaced by language-specific versions)"
```

### Full rollback
```bash
# If Phase 2 needs to be abandoned
git reset --hard HEAD~2  # Undo last 2 commits
git stash pop  # Restore pre-phase-2 backup
```

### Partial rollback (single file)
```bash
# Revert specific file to English placeholder
git checkout HEAD~1 -- fr/about.qmd
quarto render fr/about.qmd
```

---

## Post-completion Checklist

- [ ] Phase 1 verified complete (Task 1)
- [ ] English contact form split into separate include (Task 2a)
- [ ] All four French pages translated (`about`, `contact`, `index`, `thanks`) (Tasks 3-7)
- [ ] French contact form include created with French labels and `/fr/thanks.html` redirect (Task 4)
- [ ] French contact page updated to use `contact-form-fr.html` (Task 5)
- [ ] Render tests pass without errors (Tasks 8-9)
- [ ] French UI strings display correctly (TOC, search) (Task 10)
- [ ] Form redirect points to `/fr/thanks.html` and validation messages localize (Task 11)
- [ ] Content spot-checked for accuracy (Task 12)
- [ ] Shared contact form cleaned up (Task 13)
- [ ] Changes committed to git with atomic commits
- [ ] Local preview tested (`quarto preview`)
- [ ] No mixed-language content
- [ ] Links functional in French pages

---

## Success Criteria Summary

**Phase 2 is complete when:**
1. Phase 1 verified complete (both en/ and fr/ directories with proper metadata)
2. English contact form split into `contact-form-en.html` with `/en/thanks.html` redirect
3. French contact form `contact-form-fr.html` created with French labels and `/fr/thanks.html` redirect
4. All four French `.qmd` files contain authentic French content (not placeholders)
5. `en/contact.qmd` and `fr/contact.qmd` reference language-specific form includes
6. `quarto render` succeeds for entire site
7. French pages display with French UI strings (`lang: fr` working)
8. Form submission redirects to appropriate language thanks page
9. Browser validation messages localize based on `lang` attribute
10. Manual review confirms translation quality
11. Shared `contact-form.html` removed
12. Changes committed to git with clear commit messages

**Phase 2 is NOT complete if:**
- Any French page still has English prose content
- Form files not separated by language
- Shared `contact-form.html` still exists
- Form uses wrong redirect URLs (not `/en/thanks.html` and `/fr/thanks.html`)
- English contact page not updated to use `contact-form-en.html`
- Quarto render fails
- UI strings (TOC, search) remain in English
- Mixed-language content exists
- Links broken

---

## Notes

- **Translation approach:** This plan includes complete French translations. If implementing with an LLM, the LLM should generate the French content directly (not use placeholders or defer translation).
- **Form validation:** Browser-native validation messages auto-localize based on `<html lang="fr">` — no custom translation needed.
- **Quarto's built-in French:** Quarto includes French UI strings by default. Setting `lang: fr` in `_metadata.yml` activates them automatically. No custom `_language.yml` file needed unless overriding defaults.
- **Homepage listing:** The listing on `fr/index.qmd` will be empty until French blog posts are translated (Phase 4). This is expected.
- **Images:** Image paths in frontmatter (`images/profile.jpeg`) are relative to project root — no changes needed for French version.
- **Static site principle:** All changes are pure content/config. No backend, no runtime dependencies, no JavaScript required (except form submit).

---

## Estimated Scope

- **Files created:** 2 (`contact-form-en.html`, `contact-form-fr.html`)
- **Files modified:** 6 (`en/contact.qmd`, `fr/contact.qmd`, `fr/about.qmd`, `fr/contact.qmd`, `fr/index.qmd`, `fr/thanks.qmd`)
- **Files deleted:** 1 (`contact-form.html`)
- **Lines changed:** ~250 lines (form HTML + content translation)
- **Complexity:** Low (pure content translation + form split, no infrastructure)
- **Dependencies:** None (Quarto handles UI localization)
- **Risk:** Low (isolated to French content and form separation, English content preserved)

---

## Next Phase

After Phase 2 completion, proceed to **Phase 3: Language Switcher** — implement navigation between English and French versions.
