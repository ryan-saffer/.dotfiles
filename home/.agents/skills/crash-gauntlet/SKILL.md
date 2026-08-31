---
name: crash-gauntlet
description: "Runs or resumes the Kick mobile 40.29.0 crash gauntlet: discovers new production Datadog and supplied Play Console crashes, deduplicates causal problems, creates recoverable Jira Sub-tasks under NAT-2667, and coordinates isolated triage, focused fixes, verification, and independent review without pushing branches or changing Jira workflows. Use for crash-gauntlet start, resume, status, pause, or stop requests."
---

# Crash gauntlet

Coordinate the release crash investigation. The orchestrator owns scheduling, Jira, and git setup. It reads code and evidence but delegates every code edit to an engineer agent.

Read [contract.md](references/contract.md) before taking any action. Its run configuration, guardrails, Case Stages, and ledger schema are authoritative.

## Parse the request

Support these operations:

- `start`: start the configured run. This is the default when no operation is supplied.
- `resume NAT-2667`: reconstruct the run from Jira and local git state, then refill available lanes. Reject any other parent key.
- `status`: report candidate counts, Jira Case Stages, recorded active roles, branches, worktrees, and concerns. Make no mutations.
- `pause`: schedule no new roles. Receive completion notifications without polling, accept every active role report, then pause when no role is active.
- `stop`: schedule no new roles. Receive completion notifications without polling, accept every active role report, then finish without cleanup when no role is active.

The subagent API cannot interrupt or message a running agent. `pause` and `stop` therefore take effect at role boundaries, not in the middle of a role.

## Start

1. Read the configured parent and its existing Sub-tasks. Confirm the parent identity without editing or commenting on it.
2. Resolve the configured base branch to one SHA. Record that SHA for the whole run; later branch movement is irrelevant.
3. Read [discovery-and-triage.md](references/discovery-and-triage.md), perform discovery, and build a deduplicated candidate queue.
4. Inspect `NAT-2646` and PR `1700` read-only. Record the causal identity they address, then exclude only matching candidates and candidates already represented by a child ledger. Do not perform a historical Jira duplicate search beyond the configured parent.
5. Start at most three lanes. A lane begins with one triage agent and remains occupied if that candidate becomes an implemented Crash Case.
6. Process every role report through `Accept a role report`. Refill free lanes until the queue is empty or the run is paused.

Discovery ordering decides which candidates enter free lanes first. It does not justify dropping a supplied Play candidate or manufacturing a platform quota.

## Accept a triage report

Validate the report against the schema in [discovery-and-triage.md](references/discovery-and-triage.md). A malformed or missing report is an agent failure.

- `DUPLICATE`: merge its evidence into the canonical child when one exists, record `STOPPED_DUPLICATE` only when a child was already created, and release the lane.
- `UNRESOLVED`: create a Jira Sub-task, or reuse its retry child, directly at `STOPPED_NO_CAUSAL_CHAIN`. Include competing hypotheses, normalized causal frames, impact, and source identities. Do not create a branch or worktree.
- `QUALIFIED`: create a Jira Sub-task, or reuse its retry child, at `ENGINEERING_PENDING`, then set up its branch and worktree.

Only high-confidence causal identity merges candidates. Medium-confidence subsystem overlap cross-links evidence while preserving separate cases. A single case may carry both platform labels when both prove the same mechanism and focused fix.

## Set up an implemented case

1. Create the child before local git state so its key names the branch and worktree.
2. Use branch `crash-gauntlet/<CHILD-KEY>` and worktree `/Users/r.saffer/workspace/mobile-crash-gauntlet/<CHILD-KEY>/`, both rooted at the pinned base SHA.
3. Reuse existing state only when the child ledger, branch, worktree, and git HEAD consistently identify the same case. Preserve ambiguous state and stop the child at `STOPPED_COLLISION`.
4. Record setup details in Jira. A non-collision setup failure becomes `STOPPED_SETUP`.
5. Read [engineering.md](references/engineering.md), set `ENGINEERING_ACTIVE`, and launch an engineer in the isolated worktree.

## Accept an engineering report

Validate the report against [engineering.md](references/engineering.md) and independently inspect branch status, commits, and changed paths. The orchestrator may inspect but must not edit files.

- `READY_FOR_REVIEW`: require a clean worktree and a final commit containing `PR_DESCRIPTION.md`; record verification and set `REVIEW_PENDING`.
- `STOPPED_BROAD_FIX`: record `STOPPED_BROAD_FIX` and release the lane.
- `STOPPED_VERIFICATION`: record `STOPPED_VERIFICATION` and release the lane.
- `STOPPED_NO_CAUSAL_CHAIN`: record the same terminal stage and release the lane.
- `STOPPED_COLLISION`: preserve the ambiguous local state, record `STOPPED_COLLISION`, and release the lane.

For `REVIEW_PENDING`, read [review.md](references/review.md), increment `Review Pass`, set `REVIEW_ACTIVE`, and launch a fresh reviewer. Each reviewer receives the original evidence, full child ledger, complete diff from the pinned base, all commits, recorded check output, Case Brief, and prior findings.

## Accept a review report

Validate the report against [review.md](references/review.md). Reviewers inspect verification records and do not rerun commands.

- `APPROVED`: verify the branch still has a clean worktree and `PR_DESCRIPTION.md` is in the last commit, then set `READY` and release the lane.
- `CHANGES_REQUESTED`: if this was pass three, set `STOPPED_REVIEW` and release the lane. Otherwise record findings, set `REWORK_PENDING`, then launch a fresh engineer from the existing worktree at `REWORK_ACTIVE`.
- `STOPPED`: set the report's non-agent terminal reason and release the lane. Missing or malformed reviewer output follows `Agent failure` instead.

Every rework engineer reruns relevant verification, commits reviewer-requested changes separately, updates `PR_DESCRIPTION.md`, and commits that file last before the next review.

## Agent failure

A role has a best-effort budget of 40 model steps for triage, 80 for engineering or rework, and 30 for review. Put the budget in the role prompt and require a stopped report before exhaustion.

On malformed output, budget exhaustion, or agent exit:

1. Scope the attempt to the role invocation: `triage`, `engineering`, `review-<pass>`, or `rework-<pass>`.
2. For the first pre-case triage failure, create its exceptional retry child as described below.
3. Record the attempt and any returned diagnostics in the child ledger.
4. Retry that invocation once with a fresh agent and the same durable evidence and worktree.
5. After the second failure, set `STOPPED_AGENT_FAILURE`, release the lane, and continue.

Pre-case triage is the exception to creating Jira only after triage concludes. After its first failure, create a Jira Sub-task at `TRIAGE_RETRY_PENDING` with source identities, impact, attempt, and diagnostics; set `TRIAGE_RETRY_ACTIVE` before launching the retry. After a second failure, set `STOPPED_AGENT_FAILURE`. Do not create a branch or worktree until triage qualifies the candidate. This prevents `resume` from resetting the retry count.

## Resume

1. Read the parent children and parse every crash-gauntlet ledger.
2. Inspect `git worktree list --porcelain`, matching branches, each case HEAD, worktree status, commits, and `PR_DESCRIPTION.md` without modifying them.
3. Treat a recorded active role with no agent known to the current session as interrupted. Count the interrupted attempt, relaunch only when fewer than two attempts are recorded for that role invocation, and otherwise set `STOPPED_AGENT_FAILURE`. Never repeat a completed stage or automatically relaunch a terminal stage.
4. Re-run discovery to reconstruct pre-case candidates. Remove source identities already represented by a child ledger. Interrupted candidate triage may repeat.
5. Stop ambiguous branch/worktree ownership as `STOPPED_COLLISION`.
6. Refill up to three total lanes and continue the normal role sequence.

If any Jira read, create, or update needed by the run fails, schedule nothing else. Preserve local state, report the pause, and require a later `resume`.

## Finish

Return an aggregate summary in the final response only. Include discovery counts, correlations, child keys and stages, ready branches/worktrees, stopped reasons, verification exceptions, and the configured addressed exclusion. Keep durable detail in child descriptions; leave the parent untouched.
