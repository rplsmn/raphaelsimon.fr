# The November 2025 Inflection: Notes on LLM-Assisted Development

**Source**: Field notes from 10-12h daily usage, December 2025 - February 2026
**Author context**: Senior engineer, French public agency (ATIH), doctor turned engineer
**Purpose**: Base material for (1) a blog post and (2) a CEO report
**Date**: February 15, 2026

---

## Part I. The Thesis

### What changed

Before November 2025, LLMs were useful but nobody had cracked a sustainable workflow. Models hallucinated too much for production trust, and the rest of the output wasn't leagues above what a competent human could produce. Two things changed simultaneously:

1. **Claude Opus 4.5** (and models of the same class): clearly better one-shot success, better at maintaining coherence across long plans, noticeably fewer "drift" failures.

2. **CLI agents** (Claude Code, Copilot CLI, OpenCode, etc.): access to bash/powershell = full machine control. The key unlock is the combination of:
   - `grep`/`find` and other utilities to explore code without wasting tokens
   - `git` for versioning and revisions = less fear of LLM mistakes, easy rollback
   - Testing tools for longer autonomous iteration loops
   - Parallelism via git worktree, multi-agent, or sub-agents on independent tasks

Opus 4.5 + CLI = superpower. Neither alone was sufficient.

### Why November 2025 specifically

- Steve Yegge identifies **November 24, 2025** as the date "AI coding hit an event horizon" and became "the real deal" ([The AI Vampire](https://steve-yegge.medium.com/the-ai-vampire-eda6e4f07163))
- Simon Willison calls Claude Code "the most impactful event of 2025," with Anthropic crediting it for reaching "$1bn in run-rate revenue" by December 2nd ([The Year in LLMs](https://simonwillison.net/2025/Dec/31/the-year-in-llms/))
- Matt Shumer identifies late 2025 as when "new techniques unlocked much faster progress" ([Something Big](https://shumer.dev/something-big-is-happening))
- METR data shows AI task-completion capacity doubling every 7 months, with recent acceleration to 4-month cycles; models now achieve 50% success on tasks requiring up to 5 hours of human effort

### The nuance (honesty check)

Simon Willison tested Opus 4.5 extensively on sqlite-utils (20 commits, 39 files, 2000+ additions over two days) and then discovered he "kept working at the same pace" when switching back to Sonnet 4.5. His conclusion: "production coding is a less effective way of evaluating the strengths of a new model than I had expected." The inflection may lie less in raw model capability than in the maturation of **tooling** that makes these models practical for sustained work. ([Claude Opus review](https://simonwillison.net/2025/Nov/24/claude-opus/))

This is an important counterpoint. The thesis should be: **Opus + CLI agents together** = inflection. Not Opus alone.

---

## Part II. Persistent Limits

### Hallucination remains ~8-10%

The safety net is not the model, it's the methodology:
- **TDD** (test-driven development): Stemmler's divergence/convergence framework explains why. LLM output is pure divergence; tests are the convergence checkpoints that prevent spaghetti code. "When you write a test, you're converging. When you write code, you're diverging." ([Stemmler](https://khalilstemmler.com/articles/divergence-convergence-spaghetti-code/))
- **Git + GitHub**: branch-based work + human PR review
- **Lean methodology**: plan, ADR, exit criteria, definition of done, review = retrocontrol framework

Still far from total independence. Too risky for production without human oversight.

### The language mastery problem

Too risky to have LLMs code in a language you don't master for production. But what about throwaway code or self-training? Hard to say for learning, because learning requires practice, and reading LLM output is not practice.

---

## Part III. The Human Cost

### AI intensifies work, it doesn't reduce it

An 8-month study of 200 tech workers (HBR, Feb 2026) found three intensification mechanisms:
1. **Task expansion**: workers cross professional boundaries ("empowering" but accumulates into scope creep)
2. **Blurred work-life boundaries**: AI's conversational interface erodes downtime; prompting during breaks feels like "chatting"
3. **Increased multitasking**: managing multiple threads creates constant context-switching

Key finding: "Without intention, AI makes it easier to do more -- but harder to stop."

Recommended mitigations: intentional pauses, sequencing (batching, focus windows), human grounding (dialogue to restore perspectives).

Source: [HBR - AI Doesn't Reduce Work, It Intensifies It](https://hbr.org/2026/02/ai-doesnt-reduce-work-it-intensifies-it)

### Lived experience: psychological impacts

These are first-person observations from 3 months of intensive daily use:

- **Rate limit compulsion**: Feeling obligated to always hit the 5h refresh cap, otherwise "wasting." Drug dealer engagement techniques?
- **Dopamine rush**: Speed of execution creates craving for more, sometimes at the cost of not checking results
- **Planning aversion**: Preparing skills, docs, instructions feels slow; the pull to jump into prompting is strong
- **Screen hypnosis**: Watching the "executing" command line, mesmerized. The tech that should liberate me glues me to my screen
- **Intense fatigue**: Long sessions with parallel agent coordination are exhausting. The analogy: going from a bicycle to a car to a race car... to a fighter jet? Speed helps but costs concentration; the smallest error is more expensive; physical condition matters
- **Challenger Disaster pull** (cf. Simon Willison): frequently catching myself not thinking hard enough about consequences of allowing tools on machines I value
- **Attachment to suboptimal output**: Stupidly hard to re-run the same prompt for a better oneshot. I become attached to the output
- **Anthropomorphism trap**: I repeat to my intern daily not to anthropomorphize the LLM, yet catch myself doing it constantly
- **Influence susceptibility**: Even with rigorous plans, I deviate because the LLM output is persuasive. It's really good at influencing

### The fatigue question

This new productivity seems costly in fatigue. Theory: constant decision-making + rapid context switching. Even worse with parallel agents.

The fighter jet analogy works: speed helps but costs concentration, the smallest error is more expensive, and physical condition becomes important to survive the experience.

---

## Part IV. Consequences and Strategic Impact

### The value capture problem

Steve Yegge's central argument: if AI makes an engineer 10x productive, the employer captures 100% of the value. The engineer gets burnout, not 9x salary. "We're headed for a 4-hour workday or bust." ([The AI Vampire](https://steve-yegge.medium.com/the-ai-vampire-eda6e4f07163))

Today, 200EUR/month for a tool that doubles or triples productivity seems expensive to organizations. But the humans needed for equivalent output cost far more. This is an opportunity cost problem, not a budget problem.

### The junior problem

If you need senior experience to review LLM output, validate architecture, and manage plans, there is no place for juniors. But if there are no juniors, how do you train the seniors of tomorrow?

Kitze (AI Engineer World's Fair 2025) frames this as evolution from "syntax monkeys" to "vibe managers" / "AI orchestrators." Senior devs become "vibe code fixers" handling the 20% AI can't. Junior roles are more easily replaceable. ([From Vibe Coding to Vibe Engineering](https://podwise.ai/dashboard/episodes/6446247))

### The skill atrophy problem

Basic neurology: unused synaptic connections are pruned. If engineers stop writing code because AI does it, their coding skill will degrade. Need to seriously design a work methodology that maintains human competence.

### Specific ATIH impacts

1. **R as dominant language for data scientists**: No problem for exploitation/aggregation, but for restitutions (user-facing outputs), Shiny's value collapses when LLMs can do the front-end in pure JS
2. **The Capgemini model is obsolete**: "Capgemini does the front, we do the back in Shiny/Ambiorix, glue them together" makes no sense when LLMs can do the front in JS and the data scientist can build a minimal back in R + API (plumber or not)
3. **Low-skill staff**: Can we build LLM agents + simple BI tools to replace their programming tasks, letting them become executors/reviewers?
4. **Governance**: Shared instruction sets (e.g., `claude.md` files) for corporate style, normative choices, imposed everywhere?

### What it unlocks

People with sharp programming skills and the seniority to think through complex, promising projects but who lack the time or human resources to implement them. R&D and PoC work becomes dramatically more feasible solo.

---

## Part V. Sovereignty and Cost

### Price anxiety

- Current personal: 20EUR/month; real extraction is ~15EUR/day minimum from Anthropic Pro plan
- ATIH: 100 premium requests/month, then 0.04$/request = $4 to recharge 100. Each request can consume several $ in reality
- StrongDM spends ~$1,000/tokens per engineer, approximately $20,000/month per developer ([Willison, Software Factory](https://simonwillison.net/2026/Feb/7/software-factory/))

### The OSS gap

Open-source models lag ~6 months behind frontier. Can we hope for a future with personal frontier models? If so, the strategic issue is GPUs/data centers.

As a French public agency, the next priority should be serious contact with those working on sovereign AI data center strategy.

### The recursive improvement threat

Between Opus 4.5 and the previous generation, 6 months allowed a massive leap. When capabilities grow exponentially, and if frontier models achieve the capacity to autonomously produce the next generation, 6 months = eternity. Shumer confirms: "GPT-5.3-Codex was instrumental in creating itself." Amodei describes the "feedback loop gathering steam month by month."

Dario Amodei frames powerful AI as a "country of geniuses in a datacenter" -- 50 million Nobel-level intellects at 10x human speed. He predicts 10-20% sustained annual GDP growth, but warns of half of entry-level white collar jobs disappearing in 1-5 years. ([The Adolescence of Technology](https://www.darioamodei.com/essay/the-adolescence-of-technology))

---

## Part VI. The Maturity Framework (Dan Shapiro)

Dan Shapiro's five levels of AI-assisted development provide a useful frame for positioning:

| Level | Name | Description | Who's here |
|-------|------|-------------|------------|
| 0 | Manual | No AI | Pre-2023 |
| 1 | Task Automation | AI as intern for discrete tasks | Most organizations |
| 2 | Collaborative Partnership | Developer + AI pairing in flow state | "90% of AI-native developers" |
| 3 | Supervisory Management | Human reviews diffs, AI manages branches | Where most practitioners plateau |
| 4 | Autonomous Operation | Developer as PM writing specs; AI executes | Shapiro, power users |
| 5 | Dark Factory | "Black box that turns specs into software" | StrongDM experiment, <5 people teams |

Source: [The Five Levels](https://www.danshapiro.com/blog/2026/01/the-five-levels-from-spicy-autocomplete-to-the-software-factory/)

**Self-assessment**: Operating at Level 3-4 after 3 months of intensive use.

---

## Part VII. What I Built (Evidence of Impact)

Since December 2025, with LLM-assisted development:

- **raphaelsimon.fr**: Personal website (Quarto, custom CSS, Lua, multi-language)
- **autopmsi.raphaelsimon.fr**: Novel ATIH app
- **Homelab**: 5 services on Podman containers
- **Homelab homepage + API**: Always-on RPi with Wake-on-LAN
- **Tailscale network**: Home machines + phone
- **VPS for Claude Code**: Dangerous mode via Termius + Tailscale + tmux from phone
- **Teradata TPT documentation + scripts**: Solved a blocking ATIH problem (read/write tables to CSV without R/ODBC transit)
- **R package wrapping TPT scripts**: For ATIH users
- **groupeR refactor**: Key R package
- **groupeR webapp**: For March conference presentation
- **Dozens of agent skills, commands, tools**: Shared with the organization

---

## Part VIII. Maturity Assessment

### For the blog: READY

The personal observations (Part III) are strong, authentic, and timely. The topic is hot (Yegge, Willison, HBR all publishing in the same window). The "fighter jet" analogy is vivid and original. The lived experience of psychological impacts is rare and valuable -- most writers are either evangelists or skeptics. The honest middle ground (it's a superpower AND it's draining) is the most useful perspective.

**Blog angle recommendation**: "What 3 months of flying a fighter jet taught me about AI-assisted development." Personal, experiential, with the psychological observations as centerpiece. Link to references for those who want the strategic picture.

### For the CEO report: NEEDS MORE STRUCTURE

The raw material is here but needs:

1. **Quantified personal impact**: Time/cost comparisons. "Before Claude Code, this project would have taken X. With it, Y." The portfolio in Part VII is impressive but needs metrics.
2. **ATIH-specific financial modeling**: What would broad adoption cost? What does the current Capgemini model cost by comparison? What's the opportunity cost of not adopting?
3. **Concrete proposal**: The note says "create a task force / fully-fledged department." This needs a staffing plan, timeline, budget, success metrics.
4. **Risk register**: Structured list of risks (vendor lock-in, sovereignty, skill atrophy, burnout) with mitigation strategies.
5. **Peer validation**: The "Verbatims" section is empty. Collecting 3-5 quotes from respected colleagues would strengthen credibility significantly.

**CEO report angle recommendation**: "Early warning: AI-assisted development has crossed a threshold. Here's what it means for ATIH's workforce, technology choices, and strategic planning." Lead with the METR data (capability doubling every 7 months), the Amodei prediction (50% entry-level white collar jobs, 1-5 years), and the personal portfolio as proof of concept. Close with the proposal.

---

## Reference Summaries

### Dario Amodei -- "The Adolescence of Technology"
Positions 2025-2027 as AI's inflection point. "Powerful AI" = Nobel-level intelligence at 10-100x human speed, arriving in 1-2 years. At Anthropic, AI already writes significant code, creating a feedback loop where "current generation autonomously builds the next." Predicts 10-20% sustained GDP growth but warns 50% of entry-level white collar jobs may disappear in 1-5 years. Frames powerful AI as a "country of geniuses in a datacenter." Advocates blocking chip sales to China as "perhaps the most important single action."

### Steve Yegge -- "The AI Vampire" (Feb 2026)
Claims AI makes engineers genuinely 10x productive with Claude Code. Identifies November 24, 2025 as the inflection. Central concern: employers capture 100% of productivity gains while engineers burn out. The "AI Vampire" metaphor (from What We Do In The Shadows): being in the same room with AI drains energy. Conclusion: "4-hour workday or bust." Sparked significant debate about whether productivity gains actually materialize in shipped products.

### Dan Shapiro -- "Five Levels from Spicy Autocomplete to Software Factory" (Jan 2026)
Framework mapping AI automation from Level 0 (manual) to Level 5 ("dark factory" = black box turning specs into software). 90% of AI-native devs at Level 2 (collaborative pairing). CLI agents like Claude Code operate at Level 4 (autonomous operation). Introduces "technical deflation" -- the rapidly decreasing cost of AI-generated code. Organizations should defer human-hour payments to leverage cheaper AI hours.

### Simon Willison -- "Software Factory" (Feb 2026)
Analyzes StrongDM's experiment: "code must not be written or reviewed by humans." Uses scenario testing with probabilistic "satisfaction" metrics instead of traditional tests. Digital Twin Universe clones third-party services for testing at scale. Investment: ~$20,000/month per developer in tokens. Willison expresses skepticism about broader applicability. Demonstrates Level 5 is possible but expensive and narrow.

### HBR -- "AI Doesn't Reduce Work, It Intensifies It" (Feb 2026)
8-month study, 200 tech workers. Three intensification mechanisms: task expansion, blurred boundaries, increased multitasking. Key quote: "You don't work less. You just work the same amount or even more." Warning: "Without intention, AI makes it easier to do more -- but harder to stop." Recommends intentional pauses, sequencing, and human grounding.

### Simon Willison -- "The Year in LLMs" (Dec 2025)
Claude Code = most impactful event of 2025. Anthropic reached $1bn run-rate revenue by Dec 2nd. $200/month subscription tiers indicate enterprise willingness to pay. METR: 50% success on 5-hour tasks, task horizon doubling every 7 months. Chinese labs (DeepSeek, GLM-4.7, Kimi K2) now lead open-weight benchmarks. Willison built 110 tools via vibe coding throughout 2025. Phone-based development now viable.

### Simon Willison -- "Porting JustHTML" (Dec 2025)
Demonstration: 4 hours, 8 prompts, 9,000 lines, 43 commits, $29.41 API cost. The agent operated autonomously while Willison bought a Christmas tree and watched a film. Validated by html5lib test suite (6,810/6,810 tokenizer tests, 1,770/1,782 tree tests). Demonstrates genuine delegation, not pair programming. "If you can reduce a problem to a robust test suite you can set a coding agent loop loose on it with a high degree of confidence."

### Simon Willison -- "Claude Opus" (Nov 2025)
Important counterpoint. After extensive testing, Willison couldn't reliably distinguish Opus from Sonnet in production coding. "Production coding is a less effective way of evaluating the strengths of a new model than I had expected." Frontier models compete within narrow margins. The inflection may be more about tooling maturity than raw model capability. Labs should provide concrete failure-to-success examples rather than abstract benchmarks.

### Matt Shumer -- "Something Big Is Happening"
Compares current moment to February 2020 (pre-lockdown). METR capability doubling accelerating from 7-month to 4-month cycles. "GPT-5.3-Codex was instrumental in creating itself" = recursive improvement loops emerging. Amodei prediction: 50% entry-level white collar jobs in 1-5 years. Late 2025 identified as when "new techniques unlocked much faster progress." Recommendation: immediate engagement with current tools before disruption crystallizes.

### Khalil Stemmler -- "Divergence, Convergence, and Spaghetti Code"
Spaghetti code = excessive divergence without convergence checkpoints. LLM output is pure divergence; tests are convergence. The "zig-zag" pattern: write test (converge), write code (diverge), refactor (converge). Applied to LLM-assisted coding: humans must establish contracts (tests, acceptance criteria) before letting AI generate, then verify against them. Human oversight is not a bottleneck -- it's essential convergence governance.

### Kitze -- "From Vibe Coding to Vibe Engineering" (AI Engineer World's Fair, June 2025)
Developers evolve from "syntax monkeys" to "vibe managers" / "AI orchestrators." Senior devs become "vibe code fixers" handling the 20% AI can't. Junior roles more easily replaceable. Vibe engineering = using agents while remaining suspicious of 90% of output. Predicts exponential productivity for seniors who master this; existential threat to juniors.
