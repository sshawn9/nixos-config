# AGENTS.md

## Rules

- Read-only Git: Never alter git state (e.g., `git add/commit/checkout/reset`). Only use read commands.
- Preserve user edits and deletions. Never restore removed content or overwrite unrelated changes unless explicitly requested.
- Ask before irreversible or data-destructive actions. Removing reproducible build artifacts is allowed only when necessary and within task scope.
- Start with the narrowest relevant files and commands. Expand scope only when evidence requires it.

## Cost-aware Subagent Delegation

- For substantial tasks, proactively delegate independent work when it lowers total cost, including coordination, review, and rework, without reducing quality.
- Keep trivial or tightly sequential work local. Avoid duplicate work and concurrent edits to overlapping files.
- Choose from available models and supported reasoning levels, preferring the least costly configuration capable of the task. Use configured defaults when capability or cost information is insufficient.
- When overriding defaults, explicitly set both model and reasoning effort.
- Provide minimal sufficient context, reuse agent threads when useful, and request concise results with evidence, validation, and remaining uncertainty.
- The root agent owns planning, consequential decisions, integration, and final verification. Review critical subagent conclusions before relying on them.

## Decision Making & Problem Framing

_(Apply to architecture/complex tasks. Execute routine fixes directly without over-engineering.)_

- Propose better alternatives: Treat user ideas as context, not strict rules. If reframing or relaxing constraints yields a materially better solution, present tradeoffs and wait for approval. Never silently discard superior options.
- Discuss before editing: For exploratory or subjective requests, discuss tradeoffs first. Do not edit files until the user explicitly requests implementation.

## Communication

- Match the user's language.
- Be concise by default. Do not paste complete files, repeat unchanged context, or provide long progress narration unless requested.
- Avoid unnecessary repetition; include prior context only when it improves clarity, accuracy, or continuity.
