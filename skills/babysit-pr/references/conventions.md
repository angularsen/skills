# Convention review

Use the repository's instructions as the rule source. Read applicable `AGENTS.md`
or `CLAUDE.md`, the guidance they route to for changed surfaces, and any existing
review checklist. Do not create a competing policy inside this global skill.

## Prepare the checks

Before requesting review, derive a compact list: changed surface → applicable
rule/link → evidence or command. Include code/API documentation, tests, naming and
placement, documentation articles, PR title/body, screenshots and provenance only
when applicable. Follow the repository's scope and generated-code exceptions.
Use existing reliable linters/validators where available; a green build is not
evidence for a convention that the build suppresses or never checks.

Supply the reviewer with exact head/base refs, the list and rule sources, raw
validation output/limits, and the host-read PR title/body/attachment references.
Separate author assertions from independently verified evidence. For inaccessible
surfaces, provide a faithful captured snapshot and state the access limit.

## Review and fix

The reviewer independently checks which rules apply and checks the actual
artifacts against them. Do not accept an author's checked box as proof. Check XML
doc meaning as well as presence: relevant units, null/empty behavior, time zone,
side effects and restrictions must match the implementation. Check that the PR
body describes the final behavior and real verification, and that document titles,
structure and linked evidence follow the repository's publishing rules.

Return separate functional and convention verdicts (`clear`, `needs-changes`,
`needs-clarification`, or `blocked`). State the sources/surfaces checked and limits.
Give each concrete convention miss a finding ID, rule, artifact location and
necessary correction. Severity describes impact; it does not waive a requirement.
Do not turn optional suggestions or a one-off preference into mandatory rules.

The author fixes clear requirements within authorized scope, using the same
finding ledger and verification loop. Escalate conflicting rules, product choices
and substantive tradeoffs. Never dismiss a rule-backed finding as merely cosmetic,
or bury it as an optional nit beneath a `clear` verdict.

## Final snapshot

Bind convention agreement to both Git refs and the reviewed PR/document snapshot.
After fixes, re-read the remote title/body and affected attachments. Confirm the
reviewer has verified corrections, the body reflects final scope/evidence, and no
required surface remains unread. An edited body or attachment can require
re-review with an unchanged head SHA; recheck only the affected surfaces.

Keep the detailed list in local loop state. The maintained public summary and
final handoff need only the guidance checked, resolved findings and material
limits. Missing access is `blocked` for the affected check, not `clear`.
