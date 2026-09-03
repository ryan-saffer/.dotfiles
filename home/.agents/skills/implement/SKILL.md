---
name: implement
description: "Implement a piece of work based on a spec or set of tickets."
disable-model-invocation: true
---

Implement the work described by the user in the spec or tickets.

Use /tdd where possible, at pre-agreed seams.

Run typechecking regularly, single test files regularly, and the full test suite once at the end.

Before review, check documentation impact. When the implementation changes documented behavior, commands, configuration, architecture, public contracts, or agent workflows, update the affected README files, `AGENTS.md` or `CLAUDE.md`, skills, references, and user-facing docs in the same change. Leave documentation that remains accurate untouched.

Once done, use /code-review to review the work.

Commit your work to the current branch.
