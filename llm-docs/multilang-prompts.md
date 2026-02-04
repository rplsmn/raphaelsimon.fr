Using your general instructions, your skills at writing implementation plans, this site's own maintainer skill and for each of the "Implementation Phases" in @llm-docs/multilang-design-plan.md:

 - Dispatch a Claude Sonnet 4.5 subagent to write a detailed step-by-step implementation plan to llm-docs/phase-<x>-plan.md. Make it write plans optimised for LLM consumptions : atomic tasks, task success criterias, no ambiguity, no time estimates
- When this planning-sonnet subagent has finished, make it dispatch a subagent using Claude Haiku 4.5 to review the implementation plan against the macro plan. Have it implement the eventual changes based on the review. It should report back to you when it's done in a token saving manner such as "Done". Don't read what it wrote in your context window. 

- Once the phase plan is finished + reviewed, dispatch a coding subagent Claude Sonnet 4.5 to implement on a feature branch. Have it dispatch a reviewer subagent Haiku 4.5 to review the implementation against the implementation plan, and make the eventual changes based on the review. It should report back to you when it's done in a token saving manner such as "Done". Branch naming: use feature/multilang-phase-1, feature/multilang-phase-2, etc.

- When a phase is finished, trigger a PR against main and move to the next one while I review it, and repeat with the same instructions. Each phase after the first should start on a new branch from the previous one, to build upon each other. Phase progression: start the next phase immediately after creating the PR without waiting for my approval (Phase 1 branches from main. Phase 2 should branch from Phase 1's branch before -> chain of PRs).

Additional info :

- Each reviewer subagent should write their review and summaries to llm-docs in markdown files and each coding subagent should commit at each working step in case the session gets interrupted and we lose output / stdout, for easy resume
- Reviewer file naming : something like .drafts/phase-1-plan-review.md and .drafts/phase-1-implementation-review.md
- Content translation : the implementation should actually translate the content to French it's all placeholders for now there is no real content on this site.

Proceed
