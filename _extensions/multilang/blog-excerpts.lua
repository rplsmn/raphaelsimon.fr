-- blog-excerpts.lua
-- Pandoc filter that generates blog post excerpts for the homepage listing.
-- Replaces a :::{.blog-excerpts}::: div with rendered article previews.

local MAX_WORDS = 200
local MAX_POSTS = 10

local MONTHS = {
  en = {"Jan", "Feb", "Mar", "Apr", "May", "Jun",
        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"},
  fr = {"janv.", "fev.", "mars", "avr.", "mai", "juin",
        "juil.", "aout", "sept.", "oct.", "nov.", "dec."}
}

local READ_MORE = {
  en = "Read more \xE2\x86\x92",
  fr = "Lire la suite \xE2\x86\x92"
}

-- Detect language from the input file path
local function get_language()
  local filepath = quarto.doc.input_file
  if filepath then
    local lang = filepath:match("/(%a%a)/")
    if lang then return lang end
  end
  return "en"
end

-- Escape HTML special characters
local function html_escape(str)
  return str:gsub("&", "&amp;")
            :gsub("<", "&lt;")
            :gsub(">", "&gt;")
            :gsub('"', "&quot;")
end

-- Format "YYYY-MM-DD" to "D MMM, YYYY"
local function format_date(date_str, lang)
  local year, month, day = date_str:match("(%d%d%d%d)-(%d%d)-(%d%d)")
  if not year then return date_str end
  local m = tonumber(month)
  local d = tonumber(day)
  local months = MONTHS[lang] or MONTHS["en"]
  return string.format("%d %s, %s", d, months[m], year)
end

-- Find all post index.qmd files under a posts directory
local function find_posts(posts_dir)
  local posts = {}
  local handle = io.popen('find "' .. posts_dir .. '" -maxdepth 2 -name "index.qmd" -type f 2>/dev/null')
  if not handle then return posts end
  for line in handle:lines() do
    local dir_name = line:match("/posts/([^/]+)/index%.qmd$")
    if dir_name then
      table.insert(posts, { dir = dir_name, path = line })
    end
  end
  handle:close()
  return posts
end

-- Count words in a list of inline elements
local function count_inlines(inlines)
  local n = 0
  for _, el in ipairs(inlines) do
    if el.t == "Str" then
      n = n + 1
    elseif el.content then
      n = n + count_inlines(el.content)
    end
  end
  return n
end

-- Count words in a block element
local function count_block(block)
  if block.t == "Para" or block.t == "Plain" or block.t == "Header" then
    return count_inlines(block.content)
  elseif block.t == "BulletList" or block.t == "OrderedList" then
    local n = 0
    for _, item in ipairs(block.content) do
      for _, b in ipairs(item) do
        n = n + count_block(b)
      end
    end
    return n
  elseif block.t == "BlockQuote" or block.t == "Div" then
    local n = 0
    for _, b in ipairs(block.content) do
      n = n + count_block(b)
    end
    return n
  end
  return 0
end

-- Remove images and footnotes from inline elements
local function strip_inlines(inlines)
  local result = pandoc.List()
  for _, el in ipairs(inlines) do
    if el.t == "Image" or el.t == "Note" then
      -- skip
    elseif el.t == "Emph" then
      result:insert(pandoc.Emph(strip_inlines(el.content)))
    elseif el.t == "Strong" then
      result:insert(pandoc.Strong(strip_inlines(el.content)))
    elseif el.t == "Link" then
      result:insert(pandoc.Link(strip_inlines(el.content), el.target, el.title, el.attr))
    elseif el.t == "Span" then
      result:insert(pandoc.Span(strip_inlines(el.content), el.attr))
    elseif el.t == "Quoted" then
      result:insert(pandoc.Quoted(el.quotetype, strip_inlines(el.content)))
    else
      result:insert(el)
    end
  end
  return result
end

-- Clean a block: strip images, footnotes; return nil if empty after cleaning
local function clean_block(block)
  if block.t == "Para" or block.t == "Plain" then
    local cleaned = strip_inlines(block.content)
    if #cleaned == 0 then return nil end
    return block.t == "Para" and pandoc.Para(cleaned) or pandoc.Plain(cleaned)
  end
  return block
end

-- Check if a div is a callout (translation banner)
local function is_callout(block)
  if block.t ~= "Div" then return false end
  for _, cls in ipairs(block.attr.classes) do
    if cls:match("callout") then return true end
  end
  return false
end

-- Extract up to max_words of content from a list of blocks
local function extract_excerpt(blocks, max_words)
  local excerpt = pandoc.List()
  local total = 0

  for _, block in ipairs(blocks) do
    -- Skip callouts, figures, headers
    if is_callout(block) or block.t == "Figure" or block.t == "Header" then
      goto continue
    end

    local cleaned = clean_block(block)
    if not cleaned then goto continue end

    local words = count_block(cleaned)
    excerpt:insert(cleaned)
    total = total + words

    if total >= max_words then break end

    ::continue::
  end

  return excerpt, total >= max_words
end

-- Parse a post file; returns {title, date, excerpt_blocks, truncated} or nil
local function parse_post(filepath)
  local file = io.open(filepath, "r")
  if not file then return nil end
  local content = file:read("*all")
  file:close()

  local ok, doc = pcall(pandoc.read, content, "markdown")
  if not ok then return nil end

  local meta = doc.meta

  -- Skip drafts
  if meta.draft and pandoc.utils.stringify(meta.draft) == "true" then
    return nil
  end

  local title = meta.title and pandoc.utils.stringify(meta.title) or ""
  local date  = meta.date  and pandoc.utils.stringify(meta.date)  or ""

  local excerpt_blocks, truncated = extract_excerpt(doc.blocks, MAX_WORDS)

  return {
    title = title,
    date = date,
    excerpt_blocks = excerpt_blocks,
    truncated = truncated
  }
end

-- Render one excerpt item to HTML
local function render_item(post, dir_name, lang)
  local href = "blog/posts/" .. dir_name .. "/"
  local formatted_date = format_date(post.date, lang)

  -- Render excerpt blocks to HTML via pandoc
  local excerpt_html = ""
  if #post.excerpt_blocks > 0 then
    local excerpt_doc = pandoc.Pandoc(post.excerpt_blocks)
    excerpt_html = pandoc.write(excerpt_doc, "html")

    if post.truncated then
      -- Append ellipsis to the last closing </p>
      excerpt_html = excerpt_html:gsub("(</p>)(%s*)$", " ...</p>%2")
    end
  end

  local read_more = READ_MORE[lang] or READ_MORE["en"]

  return string.format(
    '<article class="excerpt-item">\n'
    .. '  <h3 class="excerpt-title"><a href="%s">%s</a></h3>\n'
    .. '  <div class="excerpt-meta"><time>%s</time></div>\n'
    .. '  <div class="excerpt-content">\n%s  </div>\n'
    .. '  <a href="%s" class="excerpt-readmore">%s</a>\n'
    .. '</article>',
    href, html_escape(post.title), formatted_date,
    excerpt_html, href, read_more
  )
end

-- Generate the full listing HTML
local function generate_listing(lang)
  local project_dir = quarto.project.directory or "."
  local posts_dir = project_dir .. "/" .. lang .. "/blog/posts"

  local post_files = find_posts(posts_dir)
  if #post_files == 0 then return "" end

  -- Parse all posts
  local parsed = {}
  for _, pf in ipairs(post_files) do
    local post = parse_post(pf.path)
    if post and post.date ~= "" then
      post.dir = pf.dir
      table.insert(parsed, post)
    end
  end

  -- Sort by date descending
  table.sort(parsed, function(a, b) return a.date > b.date end)

  -- Limit to MAX_POSTS
  local items = {}
  for i = 1, math.min(#parsed, MAX_POSTS) do
    table.insert(items, render_item(parsed[i], parsed[i].dir, lang))
  end

  return table.concat(items, "\n")
end

-- Div filter: replace .blog-excerpts with generated listing
function Div(el)
  if not el.attr.classes:includes("blog-excerpts") then
    return nil
  end

  local lang = get_language()
  local html = generate_listing(lang)

  if html == "" then
    return pandoc.Null()
  end

  return pandoc.RawBlock("html", html)
end
