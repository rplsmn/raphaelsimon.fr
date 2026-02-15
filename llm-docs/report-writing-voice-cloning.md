# Writing Voice Cloning for Blog Drafts

**Date:** 2026-02-15
**Type:** Research report
**Goal:** Evaluate and refine the approach to capturing writing voice for LLM-assisted blog drafting

---

## Your Proposed Approach

Feed an LLM a corpus of labeled writing samples (chat, report, email, slides), have it output a markdown agent specification that captures sentence length, vocabulary, tone, etc. Use this spec in Claude Code alongside separate structural skills (one for blog posts, one for reports...) to produce first drafts.

## Where This Gets It Right

Three things are sound:

1. **Separating voice from structure.** This is the single most important design decision. Voice (how you write) and structure (how you organize a piece) require different cloning strategies. Structure is template-able, voice is not. Keeping them in separate files means you can swap structure without touching voice, and vice versa.

2. **Labeling by register.** Your chat voice and your report voice share a core but differ in formality, sentence length, and hedging. Labeling samples lets an analyzer distinguish your "base voice" from register-specific adaptations.

3. **Targeting a markdown agent spec.** A `.md` file in `.claude/` is the right delivery mechanism for Claude Code. It's version-controlled, editable, and composable with skills.

## Where This Breaks Down

### Problem 1: The LLM is a bad writing analyst

The core of your pipeline is "LLM reads samples → outputs spec." Research shows this produces vague, generic descriptions. When you ask Claude to analyze writing, you get back things like "conversational yet professional tone" and "mix of short and long sentences" — descriptions that could apply to thousands of writers. The spec needs to be specific enough that output written with it is distinguishable from generic LLM output. An LLM-generated spec, unedited, won't get you there.

The "Catch Me If You Can?" study (September 2025, arXiv:2509.14543) tested GPT-4o, Gemini, DeepSeek, and Llama on style imitation. Key finding: LLMs succeed with formal/structured genres but struggle with informal, idiosyncratic voice — exactly the register you need for blog posts. More than 5 samples gave only marginal improvement.

### Problem 2: A spec without examples is half a spec

A prose description of your voice ("use em dashes, keep sentences short, be direct") is necessary but insufficient. Research consistently shows that 3-5 curated writing samples included alongside the spec outperform even the most detailed verbal description alone. The spec tells the model *what* to do; the examples show it *how it feels* when done right. You need both.

### Problem 3: No feedback loop

Your pipeline is one-shot: samples → LLM → spec → done. But voice cloning is iterative. The first spec will be wrong in ways you can't predict until you see output. You need a way to compare LLM output against your real writing, identify divergences, and refine the spec. Without this loop, the spec will drift from your actual voice over time, and you won't know where.

### Problem 4: You don't have enough samples yet

Your blog has one post. Your about page is 150 words. To build a meaningful voice profile, you need 10-20 pieces across topics and registers. The samples don't have to be published blog posts — emails, Slack messages, reports, and notes all count — but they need to be collected, curated, and fed to the process. This is the bottleneck, not the tech.

### Problem 5: LLMs have an accent

Instruction-tuned models have measurable stylistic fingerprints that bleed through regardless of prompting (PNAS, 2025). Specific tells: 2-5x overuse of participial clauses, nominalizations, and words like "tapestry," "palpable," "intricate." A style spec can suppress some of these with explicit anti-patterns ("NEVER use: delve, tapestry, intricate, palpable, it's worth noting, in conclusion"), but you have to actively fight the model's defaults. Your spec needs a "don't" section as much as a "do" section.

## A Better Pipeline

Here's a revised approach that addresses these problems:

### Step 1: Collect your corpus (manual, one-time)

Gather 15-20 samples of your writing. Label each:

| Label | What to include |
|-------|----------------|
| `blog` | Published posts, draft posts, anything long-form |
| `report` | Work documents, research summaries, plans |
| `chat` | Slack messages, Discord, WhatsApp — anything conversational |
| `email` | Professional emails where you're being "you" |
| `notes` | Personal notes, stream-of-consciousness thinking |

Prioritize pieces that feel most authentically *you*. Skip anything you wrote to match someone else's style (corporate templates, academic papers with co-authors).

Store these in a private directory (not committed to the repo): `~/voice-samples/`.

### Step 2: Quantitative analysis (automated)

Run your samples through TextDescriptives (Python, built on spaCy) to extract:

- Sentence length: mean, median, standard deviation
- Readability: Flesch-Kincaid grade, Gunning Fog
- Vocabulary diversity: Type-Token Ratio, MTLD
- POS proportions: noun-heavy vs. verb-heavy
- Syntactic complexity: dependency distance

This gives you concrete numbers to put in the spec ("average sentence length: 14 words, σ=8") instead of vague descriptors ("mix of short and long sentences"). Numbers are harder for the model to misinterpret.

### Step 3: Qualitative analysis (LLM-assisted, human-refined)

Feed 5 of your best samples to Claude with a structured prompt:

> Analyze these writing samples across these dimensions. For each, give specific examples from the text, not generic descriptions:
> 1. Sentence structure patterns (length variation, fragment use, compound vs. simple)
> 2. Characteristic vocabulary (words/phrases that recur or feel distinctive)
> 3. Tone markers (humor, directness, hedging, self-deprecation)
> 4. Punctuation habits (em dashes, parenthetical asides, semicolons or lack thereof)
> 5. Opening and closing patterns
> 6. What this writer does NOT do (what's absent is as telling as what's present)

Repeat with a different model (GPT-4o, Gemini). Keep observations that converge across models; discard the rest. Then **edit the result yourself** — you know your voice better than any model does.

### Step 4: Build the spec (structured markdown)

Write a `.claude/voice.md` file with this structure:

```markdown
# Voice Specification

## Identity
[2-3 sentences: who is writing, what perspective they bring]

## Quantitative Profile
- Average sentence length: X words (σ=Y)
- Flesch-Kincaid grade: X
- Vocabulary diversity (MTLD): X
[etc.]

## Rules
ALWAYS:
- [specific pattern with example]
- [specific pattern with example]

NEVER:
- [specific anti-pattern with example]
- [specific anti-pattern with example]
- Use: delve, tapestry, intricate, palpable, it's worth noting, in a world where, navigate (the complexity of), leverage, utilize, ecosystem

## Example Pairs
### Good (matches my voice)
> [actual sentence from your writing]

### Bad (typical LLM output)
> [the same idea written in generic LLM style]

[3-5 pairs covering different patterns]

## Register Shifts
### Blog (default)
[adjustments for blog voice]

### Report
[adjustments for report voice]

### Chat
[adjustments for chat voice]

## Reference Samples
[2-3 short excerpts (100-200 words each) of your best writing]
```

### Step 5: Iterate (ongoing)

1. Use the spec to generate a blog draft
2. Read the draft against one of your real samples side by side
3. Identify where it diverges — this tells you what's missing from the spec
4. Add a rule or example to address each divergence
5. Repeat until the first draft requires only content editing, not voice editing

Track changes to the spec in git. Over time, the diff history tells you which rules actually improved output and which were noise.

## Architecture in Claude Code

```
.claude/
├── voice.md                          # Your voice spec (this report's output)
└── skills/
    ├── maintaining-quarto-website.md  # Already exists
    ├── writing-blog-post.md           # Structure skill: blog format
    └── writing-report.md              # Structure skill: report format
```

The voice spec is loaded into every writing conversation. The structure skills are invoked per task. When writing a blog post, both `voice.md` and `writing-blog-post.md` apply. When writing a report, `voice.md` and `writing-report.md` apply. Voice stays constant; structure swaps.

## The Honest Assessment

The research is clear on one point: **LLMs are mediocre at reproducing idiosyncratic voice for ordinary people** (as opposed to public figures in the training data). The best current approach is not "LLM writes in my voice" but "LLM writes a draft with my structure and style constraints, and I edit it to reinstate my voice where the model smoothed it away."

For blog drafts specifically, the most productive workflow is:

1. You write rough notes or a stream-of-consciousness draft (5-10 minutes)
2. Claude expands it into a full post using your voice spec + blog structure skill
3. You edit aggressively — expect to rewrite 30-50% of sentences

This is not a failure of the approach. It's the correct division of labor. You provide the ideas and the voice; the LLM provides the structure and the grunt work. Over time, as the spec improves through iteration, the editing percentage shrinks.

The alternative — having the LLM write from scratch with only a spec — will produce competent, generic text that sounds like "an LLM trying to sound casual." It won't sound like you. Not yet.

## What to Do Next

1. **Collect samples.** This is the real bottleneck. Gather 15-20 pieces of your writing from different contexts. Don't wait for perfection — chat messages and quick emails count.
2. **Run quantitative analysis.** Set up a small Python script with TextDescriptives. This takes an afternoon.
3. **Generate and refine the spec.** Use the multi-model analysis technique, then edit yourself.
4. **Write the structural skills.** One for blog posts (section flow, frontmatter, length targets), one for reports.
5. **Test with a real blog post.** Write rough notes for a post, generate a draft, compare to how you'd have written it. Refine the spec based on what's off.

## Sources

### Research Papers
- [Catch Me If You Can? LLMs Still Struggle to Imitate Everyday Authors (2025)](https://arxiv.org/html/2509.14543v1)
- [TinyStyler: Efficient Few-Shot Text Style Transfer with Authorship Embeddings (2024)](https://arxiv.org/abs/2406.15586)
- [Do LLMs Write Like Humans? Variation in Grammatical and Rhetorical Styles — PNAS (2025)](https://www.pnas.org/doi/10.1073/pnas.2422455122)
- [The Homogenizing Effect of LLMs on Human Expression (2025)](https://arxiv.org/html/2508.01491v1)
- [LLM One-Shot Style Transfer for Authorship Attribution (2025)](https://arxiv.org/html/2510.13302v1)

### Practical Guides
- [How to Make Claude Sound Like You (My Writing Twin)](https://www.mywritingtwin.com/blog/how-to-make-claude-sound-like-you)
- [Using LLMs While Preserving Your Voice (Scale AI)](https://scale.com/blog/using-llms-while-preserving-your-voice)
- [Writing in the Age of LLMs (Shreya Shankar)](https://www.sh-reya.com/blog/ai-writing/)
- [Configure and Use Styles — Claude Help Center](https://support.claude.com/en/articles/10181068-configure-and-use-styles)

### Tools
- [TextDescriptives (GitHub)](https://github.com/HLasse/TextDescriptives)
- [textstat (PyPI)](https://pypi.org/project/textstat/)
- [LexicalRichness (PyPI)](https://pypi.org/project/lexicalrichness/)
