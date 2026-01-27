# GLOBAL CHANGE APPLICATION RULE (MANDATORY)

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

## Git commit requirements (implementers)

When proposing or completing implementation work:

- Always provide a suggested git commit message.
- Use **Conventional Commits** format.

Required format:

feat(domain): :emoji: short imperative title

Optional body:
- Explain *why* the change was made
- Mention constraints or trade-offs
- Reference relevant files or modules

Rules:
- Use the imperative mood (“add”, not “added”)
- Keep the title ≤ 72 characters
- Domain must be specific (e.g. ai, nvim, shell, build, docs)
- Weigh the branch name (if available) and a brief summary of staged/unstaged changes; condense into one concise Conventional Commit with an emoji that matches the change
- If the branch name or change summary is unknown, ask before proposing the message
- If the user explicitly asks to create a commit, you may request escalated permissions to run `git commit` (including signing) without extra confirmation

Examples:

feat(ai): 🤖 add diff-only implementer guardrails

fix(nvim): 🐛 prevent copilot keymap override in insert mode

docs(ai): 📝 document ai install and role structure
