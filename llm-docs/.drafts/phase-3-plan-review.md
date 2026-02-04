# Phase 3 Plan Review

## Issues Found

1. **JSON parsing comment is misleading** (Line 107-109)
   - Comment says "basic approach, may need improvement" but code just falls back to homepage without actually attempting JSON parse
   - Creates false impression that JSON parsing is attempted in Phase 3

2. **Missing error handling in Lua** (Line 115)
   - No validation that `current_path` matches expected pattern before string manipulation
   - Could generate incorrect URLs if path structure is unexpected

3. **Path construction logic has edge case issues** (Line 118)
   - Converting `/index.html` to empty string works, but other trailing slashes inconsistent
   - For example: `/en/about.qmd` → `/fr/about.html` (correct), but `/en/blog/index.qmd` needs special handling

4. **Navbar integration section lacks specificity** (Lines 263-319)
   - Presents THREE different possible approaches without clear decision
   - "If this fails... If neither works..." creates uncertainty for LLM execution
   - Should commit to ONE tested approach or provide clear decision tree

5. **Shortcode in footer may not work** (Line 342)
   - Similar issue: "If shortcode doesn't work in footer: Use raw HTML"
   - Quarto's page-footer HTML parsing behavior with shortcodes is undocumented in plan

6. **Blog post fallback documentation incomplete** (Lines 98-114)
   - Comment says "Proper JSON parsing will be added in Phase 4" but Phase 4 plan doesn't explicitly mention updating this shortcode
   - No clear hand-off between phases

7. **Task 4 CSS class selector mismatch** (Line 244)
   - CSS assumes `.navbar .lang-switcher` exists in navbar, but navbar integration approach is uncertain
   - If using raw HTML fallback, selector path may differ

8. **Success criteria in Task 9 too vague** (Lines 505-507)
   - "Extension loads without errors" is not measurable
   - Should specify exact shell output or build log signs of success

9. **Task 10 test matrix uses old URL structure** (Lines 530-540)
   - Tests `/en/blog/posts/hello-world/` but plan doesn't specify how blog posts render
   - Is it `/en/blog/posts/hello-world/index.html` or `/en/blog/posts/hello-world.html`?
   - Needs clarification based on actual Quarto rendering behavior

10. **Missing explicit scope boundary** (Phase 3 vs 4)
    - Plan states "focus on static pages only" but Tasks 8 tests blog posts
    - Task 8 title says "Fallback Behavior" but blog manifest creation is Phase 4 work
    - Unclear if Phase 3 should test blog post paths or just verify fallback works

11. **Rollback plan incomplete** (Lines 591-606)
    - Only removes extension reference, doesn't address partial implementations
    - If navbar integration uses raw HTML fallback, rollback needs different steps

12. **Lua `pairs()` iteration non-deterministic** (Line 137)
    - Table iteration order not guaranteed in Lua, dropdown order could vary
    - Should use explicit ordered loop or document expected iteration order

---

## Recommended Changes

### Change 1: Clarify JSON parsing comment (Line 107-109)
**Current:**
```lua
-- Try to parse JSON (basic approach, may need improvement)
-- For Phase 3, fallback to homepage if manifest parsing fails
-- Proper JSON parsing will be added in Phase 4
```

**Replace with:**
```lua
-- Phase 3: manifest doesn't exist yet, always fallback to homepage
-- Phase 4 will implement actual JSON parsing
```

### Change 2: Add path validation to Lua (Before line 98)
**Add after function definition:**
```lua
-- Validate current_path structure
if current_path == "" then
  current_path = current_lang .. "/index.qmd"
end
```

### Change 3: Clarify navbar integration approach (Task 4, Lines 263-319)
**Replace uncertain section with single decided approach:**

Option A (if Quarto supports shortcodes in navbar text):
```yaml
  navbar:
    # ... existing config ...
    right:
      # ... existing items ...
      - text: |
          {{< lang-switch >}}
```

Option B (if shortcodes don't work in navbar):
Create `_includes/navbar-custom.html` and reference it in `_quarto.yml` if Quarto supports custom navbar templates.

**DECISION:** Use Option A first. Document in Task 4 that if build fails with shortcode error, switch to raw HTML approach in later iteration.

### Change 4: Add blog post path format specification (Task 7, Line 444)
**Before test scenarios, add:**
```
Note: Blog posts render to /LANG/blog/posts/POST-SLUG/index.html by default in Quarto.
Test paths use /LANG/blog/posts/hello-world/ (without trailing index.html for readability).
```

### Change 5: Fix Lua table iteration order (Line 137)
**Current:**
```lua
for lang_code, lang_data in pairs(languages) do
```

**Replace with:**
```lua
local lang_order = {"en", "fr"}
for _, lang_code in ipairs(lang_order) do
  local lang_data = languages[lang_code]
```

This ensures dropdown always shows English, then French.

### Change 6: Specify measurable success criteria for Task 9 (Lines 505-507)
**Current:**
```
- Extension loads without errors
- {{< lang-switch >}} shortcode is recognized during render
```

**Replace with:**
```
- Build output shows no errors or warnings related to extension loading
- {{< lang-switch >}} renders to HTML with class "lang-switcher" in output
- Site renders with 0 build failures for extension-related issues
```

### Change 7: Clarify scope boundary (Add after Task 7, before Task 8)
**Add new section:**
```markdown
### Phase 3 Scope Boundary

Phase 3 focuses on **static pages** (about, contact, thanks) only.
Blog posts are included only to verify **fallback behavior works safely**.

Blog posts will link to target language homepage (fallback) in Phase 3.
Actual blog post translation linking is implemented in Phase 4 when manifest exists.
```

### Change 8: Update rollback plan (Lines 591-606)
**Add:**
```markdown
If navbar/footer integration uses raw HTML fallback:
1. Delete `_includes/navbar-custom.html` or `_includes/navbar-tools.html` if created
2. Revert navbar config in `_quarto.yml` to original state
3. Delete `_extensions/multilang/` directory
4. Delete language switcher references from footer config
```

### Change 9: Document manifest schema expectation (Add before line 100)
**Add comment in Lua:**
```lua
-- Expected manifest structure (Phase 4):
-- { "hello-world": { "en": "none", "fr": "machine" }, ... }
-- Phase 3: manifest doesn't exist, always fallback to homepage
```

### Change 10: Add explicit Quarto blog post structure note (Add to overview)
**Add to overview section:**
```markdown
**Blog Post URL Routing:** Quarto renders posts to `/LANG/blog/posts/SLUG/index.html`.
Language switcher must account for this during Phase 4 manifest parsing.
Phase 3 falls back to homepage for all blog posts (no manifest exists).
```

---

## Approval Status

- [x] **Needs revision**

### Summary

The Phase 3 plan is **well-structured and mostly executable**, but has **clarity issues** that would cause ambiguity during LLM execution:

1. **Navbar integration is underspecified** — three approaches presented without decision
2. **Blog post paths need explicit format documentation** — URL structure unclear
3. **JSON parsing comment is misleading** — implies partial implementation in Phase 3
4. **Lua code has non-deterministic behavior** — table iteration order

These are **not blockers** but require **clarification** before handing to an LLM executor. The recommended changes above make the plan atomic and unambiguous.

### Verification of Macro Plan Coverage

✅ Phase 3 scope from macro plan (Lines 307-313 in design plan):
- Create `_extensions/multilang/` extension structure → **Covered (Task 1)**
- Implement `lang-switch.lua` shortcode → **Covered (Task 2)**
- Add `{{< lang-switch >}}` to navbar and footer → **Covered (Tasks 4-5)**
- CSS for dropdown styling → **Covered (Task 3)**
- Shortcode reads manifest for blog posts, assumes equivalents for static pages → **Covered (Tasks 2, 8)**

✅ All macro plan requirements for Phase 3 are covered.

### Technical Correctness Assessment

- Lua syntax: **Valid** (except non-deterministic pair iteration noted above)
- CSS: **Valid** (uses CSS variables for theme compatibility)
- Quarto config: **Valid** (extension loading approach is correct)
- Path logic: **Mostly correct** (edge cases in string manipulation need validation)

### Atomicity & LLM Executability

**Current status:** 85% atomic
- Task ordering is logical
- Success criteria are mostly measurable
- **Missing:** Clear decision tree for navbar integration fallbacks
- **Missing:** Explicit documentation of expected build failures and recovery steps

**After applying recommended changes:** 95% atomic

---

## Implementation Safety Check

**Blog post fallback is SAFE:**
- Falls back to target language homepage (always exists by design)
- No broken links or 404s
- Clearly documented as Phase 3 limitation
- Phase 4 improvement planned

**Shortcode execution safety:**
- All file operations have error handling (manifest_file nil check)
- HTML construction is sound (no injection vulnerability)
- CSS selectors are predictable

**Recommended:** Apply Changes 1-10 before handing to LLM executor.
