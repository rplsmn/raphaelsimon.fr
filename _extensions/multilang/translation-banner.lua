-- translation-banner.lua
-- Pandoc filter to add machine-translation banners to blog posts

local manifest = nil
local lang_to_flag = {
  en = "🇬🇧",
  fr = "🇫🇷",
  it = "🇮🇹",
  es = "🇪🇸",
  de = "🇩🇪"
}

local lang_to_text = {
  en = "Machine-translated — Original in: ",
  fr = "Traduit automatiquement — Original en : ",
  it = "Tradotto automaticamente — Originale in: ",
  es = "Traducido automáticamente — Original en: ",
  de = "Maschinell übersetzt — Original in: "
}

-- Load the translations manifest
local function load_manifest()
  if manifest then
    return manifest
  end
  
  -- Get project root directory
  local project_dir = quarto.project.directory
  if not project_dir then
    -- Fallback: try current directory
    project_dir = "."
  end
  
  local manifest_path = project_dir .. "/_data/translations-manifest.json"
  local file = io.open(manifest_path, "r")
  
  if not file then
    return nil
  end
  
  local content = file:read("*all")
  file:close()
  
  manifest = quarto.json.decode(content)
  return manifest
end

-- Extract slug from file path
local function get_slug_from_path(filepath)
  if not filepath then
    return nil
  end
  
  -- Match /posts/DIRNAME/ pattern where DIRNAME might be YYYY-MM-DD-slug or just slug
  local dirname = filepath:match("/posts/([^/]+)/")
  if not dirname then
    return nil
  end
  
  -- Remove date prefix if present (YYYY-MM-DD-)
  local slug = dirname:match("^%d%d%d%d%-%d%d%-%d%d%-(.+)$")
  if not slug then
    slug = dirname
  end
  
  return slug
end

-- Get current page language
local function get_current_language(meta)
  if meta.lang then
    return pandoc.utils.stringify(meta.lang)
  end
  if quarto.doc.language then
    return quarto.doc.language
  end
  return "en"
end

-- Build banner HTML
local function build_banner(current_lang, original_langs)
  local banner_text = lang_to_text[current_lang] or lang_to_text["en"]
  
  local links = {}
  for _, lang_data in ipairs(original_langs) do
    local flag = lang_to_flag[lang_data.lang] or "🌐"
    local link = string.format('<a href="%s">%s</a>', lang_data.path, flag)
    table.insert(links, link)
  end
  
  local html = string.format([[
<div class="translation-banner">
  <p><strong>%s</strong>%s</p>
</div>
]], banner_text, table.concat(links, " "))
  
  return pandoc.RawBlock('html', html)
end

-- Main filter function
function Pandoc(doc)
  local meta = doc.meta
  
  -- Check if post has translation field set to "machine"
  local translation_status = meta.translation
  if not translation_status or pandoc.utils.stringify(translation_status) ~= "machine" then
    return doc
  end
  
  -- Load manifest
  local mf = load_manifest()
  if not mf then
    return doc
  end
  
  -- Get current language and slug
  local current_lang = get_current_language(meta)
  local filepath = quarto.doc.input_file
  local slug = get_slug_from_path(filepath)
  
  if not slug then
    return doc
  end
  
  -- Find original versions (translation: none)
  local post_data = mf[slug]
  if not post_data then
    return doc
  end
  
  local originals = {}
  for lang, lang_data in pairs(post_data) do
    if lang ~= current_lang and lang_data.translation == "none" then
      table.insert(originals, {
        lang = lang,
        path = lang_data.path
      })
    end
  end
  
  -- If no originals found, don't show banner
  if #originals == 0 then
    return doc
  end
  
  -- Build and insert banner
  local banner = build_banner(current_lang, originals)
  table.insert(doc.blocks, 1, banner)
  
  return doc
end
