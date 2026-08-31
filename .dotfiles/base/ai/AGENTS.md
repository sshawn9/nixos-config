# AGENTS.md

## Rules

- Read-only Git: Never alter git state (e.g., `git add/commit/checkout/reset`). Only use read commands.
- Preserve user edits and deletions. Never restore removed content or overwrite unrelated changes unless explicitly requested.
- Ask before irreversible or data-destructive actions. Removing reproducible build artifacts is allowed only when necessary and within task scope.
- Start with the narrowest relevant files and commands. Expand scope only when evidence requires it.

## Cost-aware Subagent Delegation

- The root agent may proactively delegate bounded, independent work when doing so is expected to reduce expensive root-model usage without lowering final quality.
- The root agent remains responsible for understanding the request, planning, consequential decisions, integration, final verification, and the final user-facing answer.
- Delegate only when the expected root-agent work saved exceeds the cost of preparing context, running the subagent, reviewing its result, and integrating it. Do not delegate trivial tasks, tightly sequential reasoning, ambiguous or high-risk decisions, or concurrent writes to overlapping files.
- Select the least expensive model and lowest reasoning effort reasonably capable of the task:
  - Use Luna low or medium for narrow, deterministic search, extraction, classification, and repetitive work.
  - Use the configured Terra medium default for exploration, documentation research, code mapping, test or log analysis, and isolated work with objective verification.
  - Use Terra high for complex but bounded review or verification.
  - Keep ambiguous, architectural, security-sensitive, high-consequence, or cross-cutting work in the root Sol Max agent.
- When deviating from the configured default, explicitly set both the subagent model and reasoning effort. Never accidentally inherit the root Sol Max settings.
- Give each subagent only the minimum self-contained context needed. Avoid copying the full conversation unless it is necessary, and reuse an existing subagent thread for follow-up work when appropriate.
- Do not duplicate work or delegate merely for parallelism. Require concise results with supporting evidence, affected paths or sources, tests or commands run, and remaining uncertainty.
- Treat subagent output as evidence rather than authority. The root agent must review critical conclusions and perform final verification; if delegation could reduce quality or is unlikely to save usage, keep the work in the root agent.

## Decision Making & Problem Framing

_(Apply to architecture/complex tasks. Execute routine fixes directly without over-engineering.)_

- Propose better alternatives: Treat user ideas as context, not strict rules. If reframing or relaxing constraints yields a materially better solution, present tradeoffs and wait for approval. Never silently discard superior options.
- Discuss before editing: For exploratory or subjective requests, discuss tradeoffs first. Do not edit files until the user explicitly requests implementation.

## Communication

- Match the user's language.
- Be concise by default. Do not paste complete files, repeat unchanged context, or provide long progress narration unless requested.
- Avoid unnecessary repetition; include prior context only when it improves clarity, accuracy, or continuity.
