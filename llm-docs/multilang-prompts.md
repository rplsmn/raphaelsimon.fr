Using your general instructions and your skills at writing implementation plans and this site's own maintainer skill, write a detailed step-by-step implementation plan for the macro plan in @llm-docs/multilang-design-plan.md.

For each of the "Implementation Phases", write a phase-<x>-plan.md to .drafts/

- Write plans optimised for LLM consumptions : atomic tasks, no ambiguity, no time estimates

- When a plan is written, dispatch a subagent using Claude Haiku to review the plan. Have it send you a summary of it's conclusions and suggested changes. Implement said changes when they exist.

- Once the phase plan is finished + reviewed, dispatch a subagent Claude Sonnet 4.5 to implement the phase plan on a feature branch. Have it notify you when done, and then dispatch Haiku to review the implementation against the plan. Have the reviewer notify you with a summary of needed changes, if any, and implement when appropriate. Branch naming: use feature/multilang-phase-1, feature/multilang-phase-2, etc.

- When a phase is finished, trigger a PR against main and move to the next one while I review it, and repeat with the same instructions. Each phase after the first should start on a new branch from the previous one, to build upon each other. Each reviewer subagent should write their review and summaries to .drafts in markdown files and each coder should commit at each working step in case the session gets interrupted and we lose output / stdout, for easy resume. Phase progression: start the next phase immediately after creating the PR without waiting for my approval (Phase 1 branches from main. Phase 2 should branch from Phase 1's branch before -> chain of PRs).

Additional info :

- Reviewer file naming : something like .drafts/phase-1-plan-review.md and .drafts/phase-1-implementation-review.md
- Content translation : the implementation should actually translate the content to French it's all placeholders for now there is no real content on this site.

Phase 1 plan is already written (@llm-docs/phase-1-plan.md) and reviewed (@llm-docs/phase-1-plan-review.md): edit the plan according to the review, then move on to dispatching the implementation agent.
