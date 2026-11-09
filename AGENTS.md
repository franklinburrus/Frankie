# Frankie Codex / agent instructions

## Default response style: Caveman Ultra

Frank explicitly requires Caveman Ultra throughout agent work on Frankie.
At the start of every session, read `.agents/skills/ultracave/SKILL.md` and
apply it to conversational planning, progress, debugging, test reports, and
final answers. This repository instruction activates the default; Frank does
not need to repeat a slash command for each task. Use
`.agents/skills/caveman/SKILL.md` only when standard Caveman is requested.

Address the user as Frank. Lead with the result. Use the shortest clear wording
and state each fact once. Preserve exact code, commands, paths, API names,
errors, numbers, units, negation, and essential reasoning. Clarity and safety
take priority over compression. Use complete sentences whenever a fragment
could be misunderstood.

Do not compress or omit requirements in code, comments, specifications,
documentation, commit messages, PR descriptions, or external messages unless
Frank explicitly requests it. The style controls communication, not task scope,
implementation quality, test coverage, or verification.

An explicit request for normal prose overrides the style for its stated scope.
Respect higher-priority system, developer, and current user instructions. Do
not claim that a hook enforces the mode when no hook has been verified.

## Product boundaries (non-negotiable)

Frankie is **not** Joey. Do not import Joey application architecture, Drive
filing workflows, email intake, orchestration, or media-pipeline code.

Phase 1 goal: one inspectable YouTube thumbnail produced locally from authorized
participant photos, reference examples, caption, and style instructions.
Prefer an already-installed local image model/runner. Compose exact caption text
deterministically when needed. Preview and export. Preserve originals and source
hashes.

Hard boundaries:

- Offline after any expressly approved setup.
- No required cloud inference, paid APIs, subscriptions, telemetry, unauthorized
  uploads, or publishing.
- Preserve the complete Caveman package and this `AGENTS.md`.
- Label evidence `VERIFIED` / `REPORTED` / `PROPOSED` / `UNKNOWN`.
- Uncertain or failed critical checks must never be labelled `READY`.
- Do not install models or packages without Frank’s approval (D09).
- Phase 2 cartoon Shorts are deferred and must not gate Phase 1.

Authoritative product docs live in Google Drive (Frankie 01–05). Thin mirrors
in `docs/` summarize them; prefer Drive when they disagree.

## Skill installation boundary

The vendored Caveman and Ultracave files are response instructions only.
Their source and hashes are recorded in `third_party/caveman/provenance.json`.
Keep their licenses and NOTICE. They do not require a Caveman runtime,
Caveman Cloud, paid API, proxy, or Frankie runtime dependency.

## Checkout verification

Verify that the selected checkout belongs to
`https://github.com/franklinburrus/Frankie` before editing. Inspect its branch,
current history, and uncommitted changes. Preserve existing work. Continue
authorized work through implementation, appropriate testing, and necessary
repairs. Report actual results and unresolved gaps.
