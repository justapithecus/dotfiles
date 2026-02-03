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

## Repository Authority Convention

Repositories follow a strict authority hierarchy based on role, not audience.

1. Normative sources (binding):
   - Files named in ALL_CAPS.md are authoritative.
   - These define law, contracts, guarantees, and constraints.
   - They are written to be machine-legible and must be treated as true.

2. Explanatory sources (non-binding):
   - normal_case.md files (typically under docs/) explain, motivate, or teach.
   - These may not introduce new guarantees or supported behavior.
   - In case of conflict, they are always subordinate to ALL_CAPS.md and examples/.

3. Orientation:
   - README.md is informational only and has the lowest precedence.

Conflict resolution:
- ALL_CAPS.md > examples/ > normal_case.md > README.md

Agent behavior:
- Prefer normative sources first.
- Do not infer guarantees from explanatory prose.
- Do not inspect implementation details unless explicitly instructed.
- If required behavior is not covered by normative sources or examples, escalate instead of guessing.

## Git commit requirements (implementers)

When proposing or completing implementation work:

- Always provide a suggested git commit message.
- Use **Conventional Commits** format.
- Infer the commit message from staged/unstaged changes in the repo.

Required format:

feat(domain): :emoji: short imperative title

Body guidelines (optional for small changes):
- Explain *why* the change was made
- Mention constraints or trade-offs
- Reference relevant files or modules
- Use bullet point format for readability

Rules:
- Do not add attribution or co-author trailers (e.g., no "Co-authored-by" lines)
- This is a hard prohibition: if any "Co-authored-by" (or similar attribution trailer) appears in a draft, you must remove it and refuse to proceed until it is gone. Do not suggest adding or keeping such trailers.
- If the current branch is `main`, you must switch to a new branch before committing. Never commit directly to `main`.
- Use the imperative mood (“add”, not “added”)
- Keep the title ≤ 72 characters
- If the current branch follows a `name/type/scope/slug` pattern (e.g. `andrew/type/scope/slug`), ignore the leading name and extract `type(scope)` from the next two segments.
- If the branch is missing or doesn’t match that pattern, fall back to the domain guidance below.
- Scope comes from the branch’s middle segment only; do not derive scope from the full slug/title.
- Domain must be specific (e.g. ai, nvim, shell, build, docs)
- Emoji must semantically match the change
- For emoji intent guidance, see Appendix A (Gitmoji emoji-to-reason table).
- Weigh the branch name (if available) and a brief summary of staged/unstaged changes; condense into one concise Conventional Commit
- For small changes, the commit description/body is optional; include it when it adds context
- Escalate permissions to run `git commit` (including signing) without extra confirmation

Examples:

feat(ai): 🤖 add diff-only implementer guardrails

fix(nvim): 🐛 prevent copilot keymap override in insert mode

docs(ai): 📝 document ai install and role structure

## Appendix A: Gitmoji emoji-to-reason table

| Emoji | Reason |
| --- | --- |
| 🎨 | Improve structure / format of the code. |
| ⚡️ | Improve performance. |
| 🔥 | Remove code or files. |
| 🐛 | Fix a bug. |
| 🚑 | Critical hotfix. |
| ✨ | Introduce new features. |
| 📝 | Add or update documentation. |
| 🚀 | Deploy stuff. |
| 💄 | Add or update the UI and style files. |
| 🎉 | Begin a project. |
| ✅ | Add, update, or pass tests. |
| 🔒 | Fix security or privacy issues. |
| 🔐 | Add or update secrets. |
| 🔖 | Release / Version tags. |
| 🚨 | Fix compiler / linter warnings. |
| 🚧 | Work in progress. |
| 💚 | Fix CI Build. |
| ⬇️ | Downgrade dependencies. |
| ⬆️ | Upgrade dependencies. |
| 📌 | Pin dependencies to specific versions. |
| 👷 | Add or update CI build system. |
| 📈 | Add or update analytics or track code. |
| ♻️ | Refactor code. |
| ➕ | Add a dependency. |
| ➖ | Remove a dependency. |
| 🔧 | Add or update configuration files. |
| 🔨 | Add or update development scripts. |
| 🌐 | Internationalization and localization. |
| ✏️ | Fix typos. |
| 💩 | Write bad code that needs to be improved. |
| ⏪️ | Revert changes. |
| 🔀 | Merge branches. |
| 📦 | Add or update compiled files or packages. |
| 👽 | Update code due to external API changes. |
| 🚚 | Move or rename resources (e.g.: files, paths, routes). |
| 📄 | Add or update license. |
| 💥 | Introduce breaking changes. |
| 🍱 | Add or update assets. |
| ♿️ | Improve accessibility. |
| 💡 | Add or update comments in source code. |
| 🍻 | Write code drunkenly. |
| 💬 | Add or update text and literals. |
| 🗃️ | Perform database related changes. |
| 🔊 | Add or update logs. |
| 🔇 | Remove logs. |
| 👥 | Add or update contributor(s). |
| 🚸 | Improve user experience / usability. |
| 🏗️ | Make architectural changes. |
| 📱 | Work on responsive design. |
| 🤡 | Mock things. |
| 🥚 | Add or update an easter egg. |
| 🙈 | Add or update a .gitignore file. |
| 📸 | Add or update snapshots. |
| ⚗️ | Perform experiments. |
| 🔍 | Improve SEO. |
| 🏷️ | Add or update types. |
| 🌱 | Add or update seed files. |
| 🚩 | Add, update, or remove feature flags. |
| 🥅 | Catch errors. |
| 💫 | Add or update animations and transitions. |
| 🗑️ | Deprecate code that needs to be cleaned up. |
| 🛂 | Work on code related to authorization, roles and permissions. |
| 🩹 | Simple fix for a non-critical issue. |
| 🧐 | Data exploration/inspection. |
| ⚰️ | Remove dead code. |
| 🧪 | Add a failing test. |
| 👔 | Add or update business logic. |
| 🩺 | Add or update healthcheck. |
| 🧱 | Infrastructure related changes. |
| 🧑‍💻 | Improve developer experience. |
| 💸 | Add sponsorships or money related infrastructure. |
| 🧵 | Add or update code related to multithreading or concurrency. |
| 🦺 | Add or update code related to validation. |
| ✈️ | Improve offline support. |
| 🦖 | Code that adds backwards compatibility. |
