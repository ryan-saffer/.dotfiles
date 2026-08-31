# Engineering

## Role prompt

Launch the engineer in the case worktree with an 80-step best-effort budget. Give it the complete Jira ledger, pinned base SHA, repository instructions, this file, and review findings for rework. The engineer owns code, tests, commits, and the Case Brief; it does not write Jira, push, rebase, amend, squash, or clean unrelated changes.

Require this sequence:

1. Confirm the branch, HEAD ancestry, worktree, and existing changes belong to the case. Preserve unexpected work and report a collision rather than overwriting it.
2. Revalidate the causal chain against the checked-out source. Stop when the proposed fix becomes broad, speculative, or unsupported.
3. For React Native logic, load the `tdd` and `write-unit-test` skills and establish a regression test where practical. For native crashes, ANRs, and app hangs, choose targeted build, type, lint, static, or manual reasoning checks without inventing a test seam.
4. Implement the smallest safe local change. Narrow `patch-package` fixes are allowed when the dependency seam is proven.
5. Run relevant targeted verification. Run the repository checks affected by the changed programs. Record exact commands, exit codes, and concise relevant output.
6. Investigate a failing check. A baseline exception requires proof that the same failure occurs at the pinned base and is unrelated to the diff; otherwise stop verification.
7. Commit the focused fix and regression test as one implementation commit. Commit each reviewer-requested rework separately. Never amend or squash.
8. Create or update root `PR_DESCRIPTION.md`, then commit it alone as the final commit before review.
9. Finish with a clean worktree and return the structured report before exhausting the budget.

Checkpoint after the initial implementation and each rework. A stopped case keeps all commits and uncommitted diagnostics.

## Case Brief

`PR_DESCRIPTION.md` is local-only and intentionally remains in branch history. Use this structure:

```markdown
# Paste-Ready PR Description

## Summary
...

## Root Cause
...

## Fix
...

## Verification
...

## Risk
...

# Private Operator Notes - Do Not Paste

- Jira child, Datadog issue links, and Play source paths
- Correlation reasoning and confidence
- Review history and unresolved non-blocking suggestions
- Manual follow-up or rollout observations
```

Exclude user-level Datadog data and complete raw stacks from both sections.

## Engineering report

Return exactly one fenced JSON object:

```json
{
  "outcome": "READY_FOR_REVIEW | STOPPED_BROAD_FIX | STOPPED_VERIFICATION | STOPPED_NO_CAUSAL_CHAIN | STOPPED_COLLISION",
  "causalChainValidated": true,
  "changedFiles": ["path"],
  "commits": [{ "sha": "...", "subject": "..." }],
  "verification": [{ "command": "...", "exitCode": 0, "result": "concise output" }],
  "baselineExceptions": [{ "failure": "...", "baseProof": "...", "unrelatedReason": "..." }],
  "missingTestRationale": "... or null",
  "reviewFindingsAddressed": ["pass N finding and resolution"],
  "worktreeClean": true,
  "caseBriefLastCommit": true,
  "stopReason": "... or null",
  "operatorConcerns": ["..."]
}
```

`READY_FOR_REVIEW` requires both final booleans to be true and every relevant non-baseline verification result to pass.
