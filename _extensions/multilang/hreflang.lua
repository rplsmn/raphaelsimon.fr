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
    local raw_blocks = {}
    for _, tag in ipairs(hreflang_tags) do
      table.insert(raw_blocks, pandoc.MetaBlocks({pandoc.RawBlock('html', tag)}))
    end

    if meta['header-includes'] then
      -- Append to existing header-includes (preserve Quarto's own entries)
      if meta['header-includes'].t == 'MetaList' then
        for _, block in ipairs(raw_blocks) do
          table.insert(meta['header-includes'], block)
        end
      else
        -- Wrap existing value and new blocks into a MetaList
        local new_list = pandoc.MetaList({meta['header-includes']})
        for _, block in ipairs(raw_blocks) do
          table.insert(new_list, block)
        end
        meta['header-includes'] = new_list
      end
    else
      meta['header-includes'] = pandoc.MetaList(raw_blocks)
    end
  end
  
  return meta
end
