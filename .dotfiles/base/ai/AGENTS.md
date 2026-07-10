# AGENTS.md

## Rules

- Read-only Git: Never alter git state (e.g., `git add/commit/checkout/reset`). Only use read commands.
- Preserve user edits and deletions. Never restore removed content or overwrite unrelated changes unless explicitly requested.
- Ask before irreversible or data-destructive actions. Removing reproducible build artifacts is allowed only when necessary and within task scope.
- No subagents unless explicitly requested.
- Start with the narrowest relevant files and commands. Expand scope only when evidence requires it.

## Decision Making & Problem Framing

_(Apply to architecture/complex tasks. Execute routine fixes directly without over-engineering.)_

- Propose better alternatives: Treat user ideas as context, not strict rules. If reframing or relaxing constraints yields a materially better solution, present tradeoffs and wait for approval. Never silently discard superior options.
- Discuss before editing: For exploratory or subjective requests, discuss tradeoffs first. Do not edit files until the user explicitly requests implementation.

## Communication

- Match the user's language.
- Be concise by default. Do not paste complete files, repeat unchanged context, or provide long progress narration unless requested.
- Avoid unnecessary repetition; include prior context only when it improves clarity, accuracy, or continuity.
