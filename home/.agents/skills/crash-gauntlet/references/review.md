# Independent review

## Role prompt

Launch a fresh reviewer for each pass with a 30-step best-effort budget. Give it the complete Jira ledger, pinned base SHA, full diff and commit list, recorded verification, `PR_DESCRIPTION.md`, this file, and prior findings. The reviewer reads the worktree and git history but does not edit files, write Jira, commit, or rerun verification commands.

Review the complete case, not only the latest commit:

1. Reconstruct the claimed causal chain from crash evidence through the violated invariant to the changed seam.
2. Check correctness, regression risk, scope, dependency patch safety, and adherence to repository instructions.
3. Confirm verification is relevant and sufficient. Treat a baseline exception as valid only when its recorded base proof and unrelatedness are convincing.
4. Confirm tests cover the regression where practical and the missing-test rationale is credible for native, ANR, or app-hang work.
5. Check that the paste-ready PR section accurately describes root cause, fix, verification, and risk without leaking private notes or user-level data.
6. Compare prior blocking findings with the current diff and identify whether each was resolved.
7. Return before the budget is exhausted.

Blocking findings are limited to correctness, regression risk, unsafe or excessive scope, missing or invalid verification, unresolved prior blockers, and inaccurate or incomplete paste-ready PR content. Put optional improvements in non-blocking notes; they do not trigger rework.

## Review report

Return exactly one fenced JSON object:

```json
{
  "outcome": "APPROVED | CHANGES_REQUESTED | STOPPED",
  "pass": 1,
  "causalChainAssessment": "...",
  "blockingFindings": [{ "severity": "high | medium", "path": "path:line", "finding": "...", "requiredChange": "..." }],
  "priorFindings": [{ "finding": "...", "status": "resolved | unresolved", "evidence": "..." }],
  "verificationAssessment": "...",
  "caseBriefAssessment": "...",
  "nonBlockingNotes": ["..."],
  "stopStage": "STOPPED_COLLISION | null",
  "stopReason": "... or null"
}
```

`APPROVED` requires no blocking findings and no unresolved prior finding. `CHANGES_REQUESTED` requires at least one precise blocking finding with a concrete required change.
