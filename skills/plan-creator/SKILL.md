---
name: plan-creator
description: Create a detailed PLAN.md and a phased TASKS.md for a feature or project, at a location the user chooses, with test-writing tasks and a test-and-verify checkpoint at the end of every phase.
argument-hint: "Feature, project, or change to plan"
disable-model-invocation: true
---

# Plan Creator

Turn a feature request or project idea into two linked documents:

- `PLAN.md` — the technical design: goals, current state, approach, interfaces,
  file-level changes, testing strategy, risks, and acceptance criteria.
- `TASKS.md` — the executable breakdown: phases of implementation and test tasks.
  Every phase ends by running the verification commands and confirming everything
  is green.

The documents are the deliverable. Do not implement the feature, run migrations,
or change application code.

## 1. Ground the plan

Inspect the workspace before asking anything.

1. Read the conversation for the requested outcome, constraints, and any paths or
   commands the user already named.
2. Find the repository root with `git rev-parse --show-toplevel`; fall back to the
   current working directory outside Git. Record it.
3. Read `AGENTS.md`, `CLAUDE.md`, `README.md`, and `CONTRIBUTING.md` when present.
   They carry the project's conventions, commands, and layout.
4. Locate existing plans. Search up to three levels below the repository root for
   `PLAN.md` and `TASKS.md`, excluding `node_modules`, `.git`, `vendor`, `dist`,
   `build`, and trash directories. Record every candidate directory.
5. Detect the stack and the real verification commands by reading the manifests:
   `package.json`, `Makefile`, `pyproject.toml`, `Cargo.toml`, `go.mod`,
   `composer.json`, CI workflows, or their equivalents. Record exact commands,
   including lint, typecheck, build, and test variants.
6. Read only the code needed to name the affected entry points, modules, schemas,
   configuration keys, and existing test patterns. Skip generated and vendored
   files.

Grounding is complete when you can state the objective, the affected paths, the
verification commands, and the candidate plan directories.

## 2. Resolve the contract

Use the `question` tool, if available, for one compact batch. Ask only what is
still unresolved, and give every question a recommended default. The location is
always resolved explicitly: use a path the user already named, otherwise ask and
offer the directories discovered during grounding.

Ask for:

1. **Scope** — restate the objective in one paragraph and ask the user to confirm
   or correct it. Include goals and non-goals.
2. **Location** — where `PLAN.md` and `TASKS.md` belong. Offer each existing plan
   directory, the repository root, a new directory under `docs/plans/`, and a
   custom path. A named directory receives the files inside it; a named file sets
   both its directory and the base filename. Never assume the root.
3. **Existing files** — when the destination already contains plan files, choose
   between updating them in place while preserving completed checkboxes, writing
   new files beside them under different names, and choosing another directory.
   Never overwrite silently.
4. **Deliverables** — both files by default; a single file only when the user asks.
5. **Verification** — the detected test, lint, typecheck, and build commands, the
   success condition, and what counts as manual verification. If the repository
   has no test harness, ask whether Phase 1 adds one or whether verification is
   build, lint, and explicit manual checks.
6. **Language** — default to the language of the user's request, or the language
   of existing plans when the destination already has some; ask if they differ.
7. **Constraints** — dependencies, compatibility, migrations, rollout, deadlines,
   and anything explicitly out of scope. "None known" is a valid answer.
8. **Phase granularity** — only for large work: derive phases from natural
   milestones (recommended) or target a specific number.

Present the resolved contract as a short table before writing:

| Setting | Value |
|---|---|
| Scope | ... |
| Plan directory | ... |
| Files | `PLAN.md`, `TASKS.md` |
| Verification | ... |
| Language | ... |
| Existing files | none / update / new names |

## 3. Write PLAN.md

Write the technical design so an agent can execute it without the originating
conversation. Adapt the sections to the kind of work: a documentation change
needs no data model, while a refactor needs before-and-after behavior. Testing,
acceptance criteria, risks, and open questions stay in every plan.

````markdown
# <Title>

**Status:** Draft
**Date:** <YYYY-MM-DD>
**Related:** [TASKS.md](TASKS.md)

## Goal

<One paragraph: the outcome and why it matters.>

## Non-goals

- <What this change deliberately leaves out.>

## Current state

<What exists today, grounded in real paths. What is missing, broken, or risky.>

## Approach

<The chosen design and the reasoning. Mention rejected alternatives briefly.>

## Technical design

### Architecture and data flow

<Components, responsibilities, and how data moves between them.>

### Data model and migrations

<Schemas, fields, indexes, migration order, and backfill behavior.>

### Interfaces, configuration, and CLI

<APIs, function signatures, config keys, defaults, validation, and error shapes.>

### File changes

| Path | Action | Details |
|---|---|---|
| `path/to/file` | modify / create / delete | <Concrete change.> |

Include test files, fixtures, and documentation in this table.

### Failure modes and edge cases

<Timeouts, retries, partial failure, concurrency, empty states, invalid input.>

### Compatibility, rollout, security, and performance

<Breaking changes, migration path, rollout and rollback, secrets, permissions,
limits, benchmarks.>

## Testing strategy

- **Unit:** <what is covered and where the tests live.>
- **Integration:** <real boundaries exercised.>
- **End-to-end:** <flows covered.>
- **Manual:** <what a human must check and how.>

Exact commands:

```sh
<command>
```

## Phase overview

| Phase | Outcome | Depends on |
|---|---|---|
| 1 | <Outcome.> | none |
| 2 | <Outcome.> | Phase 1 |

## Risks and mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| <Risk.> | <Impact.> | <Mitigation.> |

## Acceptance criteria

- [ ] <Observable, verifiable condition.>

## Assumptions and open questions

- <Assumption or question. Mark anything not verified in the code.>

## References

- <Specs, issues, docs, or files.>
````

Quality bar:

- Every path exists in the repository or is marked `(new)`.
- Name real symbols, fields, config keys, and commands. Replace vague phrases such
  as "handle edge cases" with the concrete cases.
- State one chosen design instead of listing menus of options.
- Record unknowns under assumptions and open questions; never silently invent.
- Keep the phase overview identical to the phase headings in `TASKS.md`.

## 4. Write TASKS.md

Open with the shared verification commands, then one section per phase.

````markdown
# <Title> — Tasks

Source plan: [PLAN.md](PLAN.md)

**Verification commands**

```sh
<command>
```

## How to use this file

- Work through phases in order unless a phase explicitly allows parallel work.
- Read the linked section of `PLAN.md` before starting a phase.
- Write the tests in the same phase as the code they cover; tests are deliverables.
- A phase is complete only when every checkbox is checked and its verification
  commands pass.
- Keep the project runnable at every phase boundary.
- Update `PLAN.md` when implementation forces a design change.

## Phase 1 — <Outcome-oriented title>

**Goal:** <What this phase delivers.>
**Depends on:** none
**Plan:** `PLAN.md` § <section>
**Files:** `path/to/file`, `path/to/test`

### Implementation

- [ ] 1.1 <Concrete change naming the file and the observable result.>
- [ ] 1.2 <Concrete change.>

### Tests

- [ ] 1.3 Add unit tests for <behavior> in `path/to/test`.
- [ ] 1.4 Add an integration test for <boundary> in `path/to/test`.
- [ ] 1.5 Add a failure-path test for <error condition>.
- [ ] 1.6 Add or update fixtures and golden files for <case>.

### Verification

- [ ] Run `<exact test command>`; it exits 0 and all tests pass.
- [ ] Run `<exact lint/typecheck/build command>`; it exits 0.
- [ ] Manually verify <observable behavior>.
- [ ] Confirm no new skipped, quarantined, or failing tests.
- [ ] Confirm every task in this phase is checked.

**Done when:** <binary condition that proves the phase is complete.>
````

Phase rules:

- Each phase delivers one coherent, independently verifiable increment. The
  project builds and the relevant tests pass at its end.
- Phase 1 includes any setup later phases need: test harness, fixtures, CI target,
  or base scaffolding.
- Tests ship with the code they cover. Every behavior change gets a test task in
  the same phase, and the task names the test path.
- The final phase runs the full verification suite and walks the acceptance
  criteria.
- Every phase ends with a `### Verification` section containing exact commands and
  the expected result. Verification is a task, never a later promise.
- Headings use exactly `## Phase <N> — <Title>`, numbered sequentially from 1.
  `phase-orchestrator` parses these headings, so keep them as the only phase-level
  headings.
- For documentation-only work, tests are link checks, build or lint checks, and a
  concrete manual review step.
- If the repository has no automated tests, Phase 1 adds a harness or defines
  explicit manual verification. Do not defer it to the end.

## 5. Cross-check both files

Run this pass before delivering:

- Every phase in the `PLAN.md` overview appears once in `TASKS.md` with the same
  number and title, and vice versa.
- Every file, interface, and design decision in `PLAN.md` has implementation or
  test tasks in `TASKS.md`.
- Every behavior change has at least one test task in the same phase.
- Every phase has `Implementation`, `Tests`, and `Verification` sections.
- Every verification command exists in the repository or is marked as added in
  Phase 1.
- Every path exists or is marked `(new)`.
- No `TBD`, bare `etc.`, or vague tasks remain.
- Both files use the same language, names, and phase numbering.
- The relative link between the two files resolves.

## 6. Deliver

- Create the destination directory when needed.
- Write `PLAN.md` and then `TASKS.md` with the `write` tool.
- Confirm both files exist at the chosen paths, the phase headings match, and the
  links resolve.
- Report the two paths, the phase count, the verification commands, and any
  assumptions or open questions. Mention what changed when updating existing plans.
- Do not commit unless the user asks.

## Guardrails

- Ask about the destination whenever the user did not name it; multiple plan
  directories are common.
- Overwrite existing plan files only after an explicit choice.
- Verify commands, paths, APIs, and schemas against the repository; mark anything
  unverified as an open question.
- Create only the requested plan documents; leave code and configuration
  untouched.
- Keep each document self-contained: an agent with only these files must be able
  to execute the plan.

## Example invocation

`plan-creator for adding OAuth login to the admin console`

Ground the repository, offer the plan directories found, confirm scope and
verification, then write `PLAN.md` and `TASKS.md` at the chosen location. Do not
start implementing until the user asks.
