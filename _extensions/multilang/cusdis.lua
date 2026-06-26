-- cusdis.lua: Injects a Cusdis comment thread at the end of blog posts.
--
-- Scope: only pages under <lang>/blog/posts/<dir>/index.qmd. Static pages,
-- the blog listing and the homepage are left untouched.
--
-- The page id / url / title are resolved at BUILD TIME from the post's real
-- output path (date-prefixed dir, which is the live URL) and frontmatter title.
-- We deliberately do NOT use the post's `hreflang` frontmatter for this: those
-- canonical paths are date-stripped and currently 404, so they would key the
-- comment thread to a dead URL. EN and FR posts have different paths, so each
-- language gets its own thread (intended).
--
-- APP_ID is a public, client-side Cusdis identifier shipped in the page HTML
-- for every visitor; it is not a secret and is safe to commit.

local APP_ID = "d23653e2-fa50-4faf-990d-3fcdb62e73a6"
local BASE_URL = "https://raphaelsimon.fr"

local HEADING = {
  en = "Comments",
  fr = "Commentaires"
}

-- Escape HTML special characters for safe attribute/text interpolation.
local function html_escape(str)
  return (str:gsub("&", "&amp;")
             :gsub("<", "&lt;")
             :gsub(">", "&gt;")
             :gsub('"', "&quot;"))
end

-- Return the site-relative path of the current blog post (with trailing
-- slash), plus its language, or nil if the current input is not a blog post.
local function post_path()
  local f = quarto.doc.input_file
  if not f then return nil end
  local lang, dir = f:match("/(%a%a)/blog/posts/([^/]+)/index%.qmd$")
  if not lang or not dir then return nil end
  return "/" .. lang .. "/blog/posts/" .. dir .. "/", lang
end

function Pandoc(doc)
  local path, lang = post_path()
  if not path then
    return doc
  end

  local title = doc.meta.title and pandoc.utils.stringify(doc.meta.title) or ""
  local page_url = BASE_URL .. path
  local page_id = path
  local heading = HEADING[lang] or HEADING["en"]

  local html = string.format([[
<section class="post-comments">
  <h2 class="comments-heading">%s</h2>
  <div id="cusdis_thread"
    data-host="https://cusdis.com"
    data-app-id="%s"
    data-page-id="%s"
    data-page-url="%s"
    data-page-title="%s"
    data-theme="dark"
  ></div>
  <script async defer src="https://cusdis.com/js/cusdis.es.js"></script>
</section>]],
    html_escape(heading),
    APP_ID,
    html_escape(page_id),
    html_escape(page_url),
    html_escape(title)
  )

  table.insert(doc.blocks, pandoc.RawBlock("html", html))
  return doc
end
