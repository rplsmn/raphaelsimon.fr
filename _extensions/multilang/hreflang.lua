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
  
  -- Add tags as raw HTML blocks in header-includes
  if #hreflang_tags > 0 then
    local blocks = {}
    for _, tag in ipairs(hreflang_tags) do
      table.insert(blocks, pandoc.RawBlock('html', tag))
    end
    
    if meta['header-includes'] and meta['header-includes'].t == 'MetaList' then
      for _, block in ipairs(blocks) do
        table.insert(meta['header-includes'], block)
      end
    else
      meta['header-includes'] = pandoc.MetaList(blocks)
    end
  end
  
  return meta
end
