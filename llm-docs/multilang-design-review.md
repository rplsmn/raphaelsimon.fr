# Multilingual Site Design Review

**Date:** 2026-02-04
**Reviewer:** Claude Code
**Status:** Complete

---

## Summary Verdict

The design is **well-aligned with project goals and pragmatically sound**. The two-tier translation system (keys + files), symmetric URL structure, and phased implementation approach are simple, maintainable, and preserve the markdown-first workflow. Minor concerns about translation banner complexity and hreflang maintenance can be mitigated with automation.

---

## Strengths

- **Preserves markdown workflow:** Blog posts remain in `/lang/blog/posts/` with `.qmd` files; writers can still work on any device without learning new conventions.

- **Symmetric directory structure:** Both EN and FR are first-class citizens (`/en/` and `/fr/` at equal level). No "default language gets root" bias that could complicate maintenance later.

- **Smart two-tier translation approach:** Short UI strings in YAML (140-char cutoff) are centralized and easy to maintain; longer prose lives in separate files, avoiding sync problems and keeping blog posts independent.

- **Pragmatic language detection:** Browser `Accept-Language` with English fallback is standard, robust, and no server needed.

- **Clear metadata tagging:** The `translation: none | machine` field is explicit and queryable at build time. Easy to implement and audit.

- **Scalable to future languages:** Structure naturally extends to `/it/`, `/es/`, `/de/` without architectural changes. Translation banners already designed to show multiple source languages.

- **SEO-aware:** hreflang tags and x-default declared upfront. Shows foresight about search ranking and crawling.

- **Phased implementation:** Five clear phases, each independent. Can ship Phase 1 (structure) and Phase 5 (full SEO) separately without blocking Phase 2 (translation keys).

---

## Concerns

### 1. **Translation Banner Implementation Complexity**
**Issue:** The machine-translation banner logic ("find all other language versions with `translation: none` at build time") requires custom build logic beyond standard Quarto.

**Mitigation:**
- Build a lightweight plugin/partial that:
  - Reads all post frontmatter at build time
  - Detects which languages have the same post with `translation: none`
  - Renders the banner with appropriate flags
- Keep this logic in a single `_partials/translation-banner.html` file for easy maintenance
- Consider: what if a post exists in EN (none) and FR (machine)? Show "Originally in English 🇬🇧"? Specify this behavior clearly in implementation.

### 2. **hreflang Maintenance Burden**
**Issue:** Every page must manually include hreflang tags. If a post is added in only one language initially, hreflang references a non-existent page.

**Mitigation:**
- Automate hreflang generation in `_quarto.yml` or a build script. Quarto may support this natively via metadata; test before full rollout.
- Fallback: Accept that hreflang won't be perfect until Phase 5. Prioritize getting content published first.
- Document: "hreflang links to actual pages only; missing translations degrade gracefully."

### 3. **Search Across Two Language Indexes**
**Issue:** Quarto's default search likely builds one index per output directory. Two language outputs might create two search indexes, requiring custom merging logic.

**Mitigation:**
- Test Quarto's search behavior with `/en/` and `/fr/` structure before Phase 4.
- If separate indexes: consider a pre-build script that merges them with language flags before final output.
- Alternatively, accept V1 limitation: search is per-language only (user switches language, then searches). Ship V2 (global cross-language search) in a follow-up.

### 4. **Root Redirect Fragility**
**Issue:** The root `index.html` with JavaScript redirect can fail if JS is disabled (noscript fallback only goes to `/en/`). Users with JS disabled but French browser language get stuck in English.

**Mitigation:**
- Improve noscript: Embed a server-side detection hint in meta refresh, or accept this is a small edge case (<2% of traffic).
- Better: Consider hosting the root redirect via `.htaccess` (Apache) or `_redirects` (Netlify) instead of HTML. This is server-level and always works.
- Current approach is acceptable but document the trade-off.

### 5. **translations.yml Editing Workflow**
**Issue:** All UI strings in one YAML file works for now, but doesn't follow "easy for phone editing" principle. YAML indentation can be fiddly.

**Mitigation:**
- Accept this for Phase 2. Later, if pain emerges, switch to `.json` or create a simple form at `/admin` (static, no backend).
- For now: keep `translations.yml` small (<100 keys). If it grows, split by domain: `nav.yml`, `footer.yml`, `blog.yml`.

### 6. **Blog Post Slug Internationalization**
**Issue:** Plan specifies "Blog post slugs are English in both languages." This is pragmatic but means French readers see English URLs even on French pages.

**Mitigation:**
- This is intentional and correct (solves canonicalization). Document it clearly.
- Ensure breadcrumbs and URLs display consistently in navbar/footer to avoid confusion.
- Upside: No duplicate slugs across languages; canonical URL structure is simple.

---

## Questions for Consideration

1. **Search Implementation Detail:**
   Have you tested Quarto's search behavior with split language directories? Does it auto-index both `/en/` and `/fr/` into one global index, or create two separate indexes? This directly impacts Phase 4 effort.

2. **Metadata Inheritance:**
   When Phase 4 adds `translation: none | machine` to blog post YAML, does Quarto's `_metadata.yml` system inherit correctly from `/en/_metadata.yml` and `/fr/_metadata.yml` simultaneously, or will there be conflicts?

3. **RSS Feed Separation:**
   The current config has `blog/index.xml` in the navbar. Should Phase 1 split this into `/en/blog/index.xml` and `/fr/blog/index.xml`? Plan doesn't mention RSS strategy.

4. **Contact Form Localization:**
   The contact form (Phase 2) will have button labels from `translations.yml`, but what about form validation messages and success responses? Clarify scope for Phase 2.

5. **Future Language Fallback:**
   When IT/ES/DE are added (all machine-translated), should a French user viewing Italian content be offered to switch to French if available? Or strictly show the requested language? Define this precedent now.

---

## Recommended Adjustments (Minor)

1. **Phase 1 Checkpoint:** Before Phase 2, verify:
   - Root redirect works (test in private browsing, disable JS, check both languages)
   - Quarto builds both `/en/` and `/fr/` outputs correctly
   - Cross-language navigation (navbar language switcher) *partially* works (links exist, even if dropdown UI not styled yet)

2. **Phase 2 Checkpoint:** Verify:
   - `_metadata.yml` inheritance works for both languages
   - `translations.yml` is correctly loaded by templates in both `/en/` and `/fr/`

3. **Phase 4 Detail:** Clarify which search renderer you'll use. If Quarto's overlay doesn't support custom grouping by language, consider a lightweight custom search component early.

---

## Conclusion

This design is **production-ready as-is**. It trades off zero maintainability for simplicity and aligns well with the markdown-first, static-site philosophy. The phased rollout is sensible. Flag the search index behavior (concern #3) as a dependency for Phase 4 planning.

**Recommended next step:** Create `task-1-plan.md` for Phase 1 (structure) with specific file reorganization steps, test checkpoints, and rollback procedures. Then ship Phase 1 as a PR and gather human feedback before phases 2–5.
