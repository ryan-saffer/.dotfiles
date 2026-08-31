# Run contract

## Configuration

| Field | Value |
| --- | --- |
| Target release | `40.29.0` |
| Base branch | `upcoming/40.30.0` |
| Jira parent | `NAT-2667` |
| Jira project/component | `NAT` / `RN Mobile` |
| Play evidence | `/Users/r.saffer/Downloads/40.29.0 crash logs/1.log` through `12.log` |
| Addressed exclusion | `NAT-2646`, open PR `1700` |
| Worktree root | `/Users/r.saffer/workspace/mobile-crash-gauntlet/` |
| Maximum lanes | `3` across triage, engineering, review, and rework |
| Maximum review passes | `3` |

Play filenames are descending impact order. The supplied files are authoritative that these Android problems are new in the supplied month; they do not contain affected-user totals.

## Guardrails

- Query production Datadog data with `service:com.kick.mobile` and `env:production` in every supported filter.
- Datadog access is read-only. Jira mutations are limited to creating and updating crash-gauntlet Sub-tasks under `NAT-2667`.
- Leave Jira workflow statuses unchanged. Leave `NAT-2667` unchanged, including its description and comments.
- Keep branches local. Create no pull request, push, deployment, Datadog mutation, rebase, squash, amend, or automatic cleanup.
- Preserve all unrelated worktree changes. A collision is a stop condition, not a cleanup instruction.
- The orchestrator serializes Jira writes and never edits code. Role agents never write Jira.
- Use the pinned base SHA for every case.
- Keep user-level or sensitive source data out of Jira, git, prompts, and reports. This includes names, user IDs, session IDs, IP addresses, precise locations, URLs carrying identifiers, message content, and raw event payloads from Datadog or Play evidence.
- Change generated native projects through `app.config.ts` or `config-plugins/`, following repository instructions.

## Case Stages

Pending and active stages:

```text
TRIAGE_RETRY_PENDING
TRIAGE_RETRY_ACTIVE
ENGINEERING_PENDING
ENGINEERING_ACTIVE
REVIEW_PENDING
REVIEW_ACTIVE
REWORK_PENDING
REWORK_ACTIVE
```

Terminal stages:

```text
READY
STOPPED_NO_CAUSAL_CHAIN
STOPPED_AGENT_FAILURE
STOPPED_DUPLICATE
STOPPED_BROAD_FIX
STOPPED_VERIFICATION
STOPPED_REVIEW
STOPPED_SETUP
STOPPED_COLLISION
```

`READY` guarantees an approved Focused Fix, relevant green verification, a clean worktree, and `PR_DESCRIPTION.md` in the final local commit. A check failure proven to occur at the pinned base and unrelated to the change is recorded as a baseline exception rather than blocking readiness.

## Jira child

Create an unassigned `Sub-task` under `NAT-2667`, retain its default workflow status, explicitly set component `RN Mobile`, verify the resulting child fields, and add `crash-gauntlet`, `release-40.29.0`, plus each applicable platform label (`android`, `ios`, or both).

```text
crash-gauntlet
release-40.29.0
android
ios
```

Use summary form `[Platform][40.29.0] <failure mechanism>`. Use `[Android/iOS]` for a proven cross-platform case.

The orchestrator owns the complete description and updates it as one recovery ledger:

```markdown
# Crash Gauntlet Case

Case Stage: `ENGINEERING_PENDING`
Review Pass: `0`
Role Invocation: `engineering`
Role Attempt: `0`
Target Release: `40.29.0`
Base SHA: `<sha>`
Platforms: `android`, `ios`

## Source Identity
- Datadog issue IDs and stable fingerprints
- Play filenames
- Correlation confidence and canonical/related cases

## Impact
- Distinct affected-user counts and occurrences when available
- Source ranking when counts are unavailable

## Causal Evidence
- Short normalized causal stack
- Observed failure
- Violated invariant
- App or dependency path to the invariant
- Focused seam, or unresolved competing hypotheses

## Local State
- Branch
- Worktree
- Commit SHAs

## Verification
- Commands, outcomes, and relevant excerpts
- Proven baseline exceptions
- Missing-test rationale for native/ANR/app-hang work

## Review History
- Pass, reviewer outcome, blocking findings, and resolution

## Attempts
- Role, attempt, outcome, and diagnostics

## Stop Reason
- Terminal rationale, if stopped
```

Write source paths and concise normalized frames rather than complete raw stacks.

## Jira write boundary

Write the next stage before launching its role. After a role returns, first validate its report and local state, then atomically replace the ledger with the resulting stage and evidence. A failed Jira write pauses the entire run before another role is scheduled.
