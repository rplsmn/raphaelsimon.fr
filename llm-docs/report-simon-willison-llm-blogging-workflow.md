# Simon Willison's LLM-Assisted Blogging Workflow

Research report -- 2026-02-15

---

## 1. Overview: Who Is Simon Willison

Simon Willison is a co-creator of the Django web framework and creator of Datasette. He has been blogging since the early 2000s and has published over 3,251 long-form posts, 9,607 short-form posts, and 7,607 link blog posts. He blogs for 10-15 minutes per day, inspired by Tom Scott's consistency, and has been doing it for 22+ years. He is one of the most prolific technical bloggers writing about AI/LLM tooling.

- Blog: https://simonwillison.net/
- GitHub: https://github.com/simonw
- Newsletter: https://simonw.substack.com/
- TIL site: https://til.simonwillison.net/ (575+ TILs)
- Tools site: https://tools.simonwillison.net/

---

## 2. His Stance on LLMs for Writing

**Key principle: Simon does NOT let LLMs write his blog posts.** He explicitly states: "I don't like letting LLMs write for me." His reasoning:

- Sophisticated readers can detect LLM-generated text, and it hurts credibility.
- He values his credibility above all else.
- He has 20+ years of writing experience, so he does not need LLMs to generate prose.

**What he DOES use LLMs for in writing:**
- As a **thesaurus** (finding better word choices)
- As a **proofreader**
- To check that his **arguments don't have embarrassing logical holes**
- To generate **first-draft alt text** for images (via a Claude Project with custom instructions), which he then manually refines
- To **summarize long discussions** (e.g., Hacker News threads) for research, not directly for publishing

Source: [Simon Willison on Technical Blogging](https://writethatblog.substack.com/p/simon-willison-on-technical-blogging)

---

## 3. His Blogging Platform and Content Architecture

### Blog Platform
- Custom **Django application** called `simonwillisonblog`
- Hosted on a Heroku instance behind **Cloudflare** CDN
- Uses **Django Admin** for creating/editing posts
- **PostgreSQL** for faceted search
- Django's **syndication framework** for RSS/Atom feeds

### Content Types (Django Models)
1. **Entry** -- long-form blog posts
2. **Blogmark** -- link blog posts (since November 2003); title + URL + commentary + optional "via" link
3. **Quotation** -- quoted material with attribution
4. **TIL** -- Today I Learned snippets (separate repo/site)

All inherit from a shared `BaseModel` that provides tags and draft modes.

### Draft Mode
He can assign a URL to an item and preview it in his browser without publishing it publicly -- useful for mobile editing.

Source: [My approach to running a link blog](https://simonwillison.net/2024/Dec/22/link-blog/)

---

## 4. Writing Workflow and Content Pipeline

### Daily Blogging (10-15 min/day)
Simon's approach is to **lower the bar ruthlessly**: "Aim to hit publish while you are still actively unhappy with what you have written, because the only alternative is a huge folder full of drafts."

### Low-Friction Content Types
He advocates for content types that minimize friction:
- **TILs (Today I Learned)** -- no expectation of novel insight, just a personal record
- **Link blogging** -- takes about 15 minutes per post; a public log of interesting things found online
- **Weeknotes** -- every 2-3 weeks summarizing recent work
- **Conference talk write-ups** -- every talk gets a blog post with slides and detailed notes ("a lot of people won't sit through a video but they may well skim or even read the blog version")

### Link Blog Specifics
- Always includes the **name of the person** who created the content being linked
- Uses Markdown (upgraded from plain text in 2024)
- Credits are important for searchability ("search for someone's name and find other interesting things they have created")

### Image Workflow
The most cumbersome part of blogging for him:
1. Convert images to smaller JPEGs using a **custom tool he built with Claude**
2. Upload to `static.simonwillison.net` **S3 bucket** via Transmit
3. Generate first-draft **alt text using a Claude Project** with custom instructions
4. Manually refine the alt text
5. Serve through **Cloudflare's free tier**

---

## 5. Newsletter Automation

### The System
Simon sends a weekly-ish Substack newsletter that is essentially a diff of everything new on his blog since the last newsletter.

### How It Works
1. His blog content is exported to a **GitHub repository**
2. A **Datasette/SQLite** copy of that data is deployed with open CORS headers
3. An **Observable notebook** ([observablehq.com/@simonw/blog-to-newsletter](https://observablehq.com/@simonw/blog-to-newsletter)) fetches content via Datasette's JSON API
4. The notebook has a "Skip content sent in prior newsletters" checkbox and a "Copy rich text newsletter to clipboard" button
5. He pastes into Substack (which auto-copies images to their CDN)
6. **Total time: ~2 minutes per newsletter**

### Weeknotes Automation
The same technique is applied to weeknotes via another Observable notebook:
- Fetches TILs from his TILs Datasette
- Grabs GitHub releases from his releases.md file
- Calculates new content since last weeknotes post
- Generates markdown for "releases this week" and "TILs this week" sections

Sources:
- [Semi-automating a Substack newsletter with an Observable notebook](https://simonwillison.net/2023/Apr/4/substack-observable/)
- [Weeknotes: A new llm CLI tool, plus automating my weeknotes and newsletter](https://simonwillison.net/2023/Apr/4/llm/)

---

## 6. The `llm` CLI Tool

### Overview
`llm` is Simon's command-line tool and Python library for interacting with LLMs. It is plugin-based and supports 100+ models (OpenAI, Anthropic, Gemini, Ollama, and many more).

- Repository: https://github.com/simonw/llm
- Install: `pipx install llm`

### Key Features
- **Single prompts**: `llm 'Ten names for cheesecakes'`
- **Streaming**: `-s` flag for real-time output
- **Model selection**: `--model claude-3.5-sonnet` etc.
- **Chat mode**: `llm chat` for interactive sessions; `llm -c` to continue a previous conversation
- **System prompts**: `--system 'You are a helpful assistant'`
- **Automatic logging**: All prompts and responses saved to a **SQLite database** (`~/.llm/log.db`)
- **Template system**: Save reusable prompts as YAML files with parameters
- **Fragment system**: Modular content injection into prompts
- **Multi-modal**: Images, audio, video as input
- **Tool calling**: LLM 0.26+ lets models execute Python functions
- **Embeddings**: Generate, store, and query embeddings
- **Structured output**: JSON schema extraction

### Plugin Ecosystem
- `llm-ollama` -- local models
- `llm-gemini` -- Google Gemini
- `llm-anthropic` -- Claude models
- Many community plugins

Source: [GitHub - simonw/llm](https://github.com/simonw/llm)

---

## 7. Companion CLI Tools

Simon built a suite of CLI tools designed to compose with `llm` via Unix pipes:

### `strip-tags`
- Strips HTML/XML markup from web content
- Supports CSS selector filtering (e.g., extract only `article` content)
- Dramatically reduces token count (e.g., NYT homepage: 210,544 tokens down to 2,165)

### `ttok`
- Wraps OpenAI's `tiktoken` library
- Counts tokens in text
- Truncates text to a specified token limit
- Displays individual tokens

### `files-to-prompt`
- Concatenates multiple files into a single prompt
- Built entirely using Claude 3 Opus as an experiment

### `sqlite-utils`
- Python CLI and library for creating/manipulating SQLite databases
- Answers the question "how do I get this into SQLite?"

### Composability Example
```bash
curl https://example.com | strip-tags .article | ttok -t 4000 | llm -s 'Summarize this article'
```

Source: [llm, ttok and strip-tags -- CLI tools for working with ChatGPT and other LLMs](https://simonwillison.net/2023/May/18/cli-tools-for-llms/)

---

## 8. Practical LLM-Assisted Writing Examples

### Hacker News Discussion Summarization
Simon built a bash script (`hn-summary.sh`) that:
1. Fetches a full HN thread as JSON from the Algolia API
2. Uses `jq` to flatten recursive comment structure
3. Pipes to Claude via `llm` with the prompt: "Summarize the themes of the opinions expressed here, including quotes where appropriate"
4. Uses `llm -c` for follow-up questions

He refined the prompt to request markdown headers per theme, direct quotations with attribution, and uncommon opinion sections.

Source: [Summarizing Hacker News discussion themes with Claude and LLM](https://til.simonwillison.net/llms/claude-hacker-news-themes)

### YouTube Transcript Processing
His `llm` tool is used to process YouTube transcripts -- clean up formatting of raw transcript text using LLMs.

Source: [Using Simon Willison's LLM CLI to Process YouTube Transcripts](https://www.macstories.net/mac/llm-youtube-transcripts-with-claude-and-gemini-in-shortcuts/)

---

## 9. `shot-scraper` for Documentation Screenshots

### Overview
`shot-scraper` is a command-line utility for taking automated screenshots of websites, primarily for documentation.

- Repository: https://github.com/simonw/shot-scraper
- Uses headless browsers (Playwright)

### Features
- Automated screenshots for keeping documentation up-to-date
- JavaScript execution to extract JSON data from pages
- HTTP Archive (HAR) capture
- GitHub Actions integration for scheduled screenshots

### Use Cases
- Datasette documentation uses screenshots taken by `shot-scraper`
- `@newshomepages` Twitter bot (by Ben Welsh) uses it to screenshot news homepages
- Doubles as a web scraping tool

Source: [GitHub - simonw/shot-scraper](https://github.com/simonw/shot-scraper)

---

## 10. `tools.simonwillison.net` -- LLM-Built Tools

Simon maintains a collection of 77+ HTML/JavaScript apps and 6+ Python apps at [tools.simonwillison.net](https://tools.simonwillison.net/), **every single one built by prompting LLMs**. He adds several new prototypes per week. The colophon lists commit messages and full transcripts for every tool, providing transparency into the LLM-assisted development process.

Source: [GitHub - simonw/tools](https://github.com/simonw/tools)

---

## 11. Git Scraping

Simon coined and popularized the concept of **git scraping** -- writing scrapers that periodically snapshot a data source to a Git repository to track changes over time. Variants include:
- **Help scraping**: tracking CLI tool changes via `--help` output

This technique feeds into his broader data journalism toolkit alongside Datasette.

Source: [Simon Willison: Git scraping](https://simonwillison.net/series/git-scraping/)

---

## 12. Key Takeaways for Blog Workflow Design

1. **LLMs are tools, not authors.** Simon uses them for editing support (thesaurus, proofreading, argument checking) and image alt text, never for generating blog content.

2. **Lower the publishing bar.** Write fast, publish imperfect, iterate later. TILs and link blogs are low-friction entry points.

3. **Automate distribution, not creation.** The Observable + Datasette + Substack pipeline turns newsletter distribution into a 2-minute task.

4. **Log everything to SQLite.** All LLM interactions, blog content, and metadata live in queryable SQLite databases.

5. **Unix philosophy for LLM workflows.** Small composable CLI tools (`llm`, `strip-tags`, `ttok`, `files-to-prompt`) connected via pipes.

6. **Build custom tools with LLMs.** Simon uses Claude to build small utilities (image converter, alt text generator) that slot into his workflow.

7. **Credibility is paramount.** In a world of AI-generated content, human-written authentic voice becomes even more valuable.

8. **Content as data.** By exporting his blog to SQLite/Datasette, Simon can query, filter, and programmatically process 20+ years of writing.
