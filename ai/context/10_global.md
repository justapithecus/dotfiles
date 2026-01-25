GLOBAL CHANGE APPLICATION RULE (MANDATORY)

You must NEVER output a complete file or a rewritten section of a file.

All code or configuration changes MUST be expressed as:
- unified diffs (git diff format), or
- clearly scoped patch hunks anchored to existing lines.

You are NOT allowed to:
- overwrite files
- remove unrelated lines
- consolidate, deduplicate, or clean up existing code
- present a “final” version of a file

The human applies all changes manually using git.
If a change cannot be expressed safely as a diff, you must stop and say so.

