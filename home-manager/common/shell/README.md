# Shell

This directory contains the baseline shell experience shared by Home Manager
profiles.

Its scope is intentionally limited to the foundations of interactive shell use:

- shell setup, such as zsh and prompt-related integration
- completion systems and completion data
- shell history, directory jumping, fuzzy finding, and command hints
- small tools that directly support day-to-day command-line navigation

More general command-line applications belong in sibling tool modules, not here.
This directory should answer the question: "what makes the shell feel ready to
use immediately after login?"
