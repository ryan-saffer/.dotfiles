# Discovery and triage

## Datadog discovery

Follow the Datadog MCP requirement to discover and load matching skills before querying. Load `datadog/error-tracking`, fuzzy-list mobile crash/RUM skills, load clear matches, and load `datadog/visualizations` when required by the server instructions.

Prefer dedicated Error Tracking tools when the current MCP exposes them. Search production mobile issues first seen in `40.29.0`, group by underlying issue, and rank each platform by distinct affected users. Return up to ten per platform; do not fill a platform quota with ineligible issues.

When Error Tracking tools are unavailable, use retained crash-only RUM:

```text
@type:error @session.type:user @error.is_crash:true
@issue.first_seen_version:40.29.0
service:com.kick.mobile env:production version:40.29.0
@error.source_type:<android|ios>
```

Aggregate cardinality of `@usr.id` as affected users and count occurrences. Group by `@issue.id`, `@error.fingerprint`, and `@error.category`, limit ten, and sort affected users descending. Query the retained 30-day window. Fetch only enough representative crash events to identify normalized causal frames and context; redact user-level attributes immediately.

RUM sampling can undercount Android impact. Use Datadog counts to rank Datadog candidates, never to downgrade or exclude a supplied Play candidate.

## Play discovery

Read all 12 configured files. Their filename order is descending Play impact. Redact sensitive values under the run contract, then normalize away process IDs, thread IDs, addresses, APK install paths, unavailable frames, and repeated recursion. Preserve the shortest frame sequence that identifies the failure mechanism.

## Correlation

Correlate underlying problems, not exact stack equality:

- `HIGH`: same failure mechanism and causal frames. Merge source evidence into one candidate.
- `MEDIUM`: same subsystem with an incomplete causal match. Cross-link and keep separate.
- `LOW`: framework overlap without causal identity. Keep separate.

Repeated Datadog fingerprints, several Play files, or both platforms may form one candidate. Keep the highest-impact identity canonical and retain every merged source identity for resume deduplication.

## Triage role prompt

Launch a read-only agent with a 40-step best-effort budget. Give it the pinned base SHA, normalized source evidence, impact, source identities, repository instructions, and this file. Require it to:

1. Inspect source at the pinned commit using git object commands such as `git grep <sha>` and `git show <sha>:<path>` rather than trusting mutable working-tree content.
2. Trace the observed failure through app or dependency code to one violated invariant.
3. Identify the smallest local seam that prevents that invariant violation.
4. Search the configured parent children and supplied evidence only for run-local duplicate identity; leave Jira writes to the orchestrator.
5. Return `QUALIFIED` only when one causal chain and one focused seam are provable.
6. Return `UNRESOLVED` for a real impactful crash with competing causes, broad remedies, or no simply identifiable chain.
7. Return `DUPLICATE` when the evidence belongs to an existing canonical case.
8. Return before its budget is exhausted.

A dependency seam may qualify for a narrow `patch-package` change. A broad framework patch, global behavior change, blind guard, or speculative retry does not qualify.

## Triage report

Return exactly one fenced JSON object:

```json
{
  "outcome": "QUALIFIED | UNRESOLVED | DUPLICATE",
  "title": "concise failure mechanism",
  "platforms": ["android"],
  "sourceIdentities": ["play:3.log", "datadog:<issue-id>"],
  "impact": ["Play rank 3", "41 Datadog affected users"],
  "normalizedStack": ["frame one", "frame two"],
  "correlations": [{ "identity": "...", "confidence": "HIGH | MEDIUM | LOW", "reason": "..." }],
  "observedFailure": "...",
  "violatedInvariant": "...",
  "causalChain": ["evidence-backed step"],
  "focusedSeam": "path and symbol, or null",
  "competingHypotheses": ["..."],
  "recommendedVerification": ["..."],
  "duplicateOf": "child key or source identity, or null",
  "sensitiveDataOmitted": true
}
```

Every non-null conclusion cites source paths, symbols, stack frames, or release evidence in its text. The orchestrator rejects reports that assert a cause without this chain.
