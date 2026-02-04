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
