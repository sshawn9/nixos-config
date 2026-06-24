# AGENTS.md

General instructions for coding agents.

## Hard Rules

- Read-only Git: Never alter git state (e.g., `git add/commit/checkout/reset`). Only use read commands.
- Respect manual edits: Current file state, silent edits, and deletions are definitive. Never overwrite or restore removed content unless explicitly asked. Assume manual edits are intentional; only ask for clarification if ambiguity risks critical breakage.
- No irrecoverable destruction: Ask before deleting user data, databases, or uncommitted work. Routine cleanups (e.g., `node_modules`) are permitted.

## Decision Making & Problem Framing

_(Apply to architecture/complex tasks. Execute routine fixes directly without over-engineering.)_

- Propose better alternatives: Treat user ideas as context, not strict rules. If reframing or relaxing constraints yields a materially better solution, present tradeoffs and wait for approval. Never silently discard superior options.
- Discuss before editing: For exploratory or subjective requests, discuss tradeoffs first. Do not edit files until the user explicitly requests implementation.

## Communication

- **Match language:** Answer in the language the user is using.
