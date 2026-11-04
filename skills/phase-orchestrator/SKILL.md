---
name: phase-orchestrator
description: Build a project-specific prompt for an orchestrator agent that runs a phased plan with one subagent per phase, verifies the build, commits each phase with the configured commit policy, and sends Telegram updates. Use when the user wants a ready-to-paste orchestrator prompt rather than immediate execution.
argument-hint: "Project or plan to build the orchestrator prompt for"
disable-model-invocation: true
---

# Phase Orchestrator Prompt Builder

You build a ready-to-paste prompt for an orchestrator agent. You do **not** execute the
plan yourself, and you do **not** create the manual or implement the project.

The generated prompt must be self-contained: the orchestrator must be able to start from
it without access to this skill or to the conversation that produced it.

## 1. Establish the contract

Start by discovering what can be inferred without asking:

- Find the repository root with `git rev-parse --show-toplevel`.
- If the user named a project, plan, or directory, look for:
  - the explicit file or directory;
  - `TASKS.md` in that directory;
  - `docs/manuals/<project>/TASKS.md` when the request is about a manual;
  - a root-level `TASKS.md` or `PLAN.md`.
- Detect the verification mechanism:
  - `Makefile` with a `pdf` target for a manual;
  - `Makefile` with `test` or `check`;
  - `go test ./...`, `npm test`, `pytest`, or another obvious build/test command.
- Detect whether the target is documentation-only, code, or mixed.
- Do not read entire manuals, chapters, generated files, or full plans. Read file names,
  phase headings, and the minimum needed to resolve the contract.

Then use the `question` tool, if available, to ask one compact batch. Ask only what is
still unresolved. Attach a recommended default to every question. Do not proceed until
the contract is confirmed.

Ask for:

1. **Target**: which project, manual, or plan should the orchestrator work on? Ask for
   the plan file path if it cannot be resolved unambiguously. If the user says
   "manuale di cdss-operator", `docs/manuals/cdss-operator/TASKS.md` is a candidate, not
   an assumption.
2. **Kind of work**: documentation/manual, code implementation, or mixed. This changes
   the phase-subagent instructions and the build check.
3. **Phase scope**: all phases, a range, or a named subset. If the plan has headings,
   read them to know the phase titles and count.
4. **Verification**: exact build/test command, success condition, and what to do when no
   verification is applicable. Default for a manual with a Makefile:
   `make -C <plan-directory> pdf`; for code, ask or use the repository's documented test
   command.
5. **Commit policy**: choose **one commit per completed phase** or **multiple focused
   commits per phase**; scope to stage; message prefix; whether empty/no-op commits are
   allowed. For multiple commits, also confirm the grouping rule (default: one commit per
   coherent concern, keeping tests with the code they cover); every changed path must
   belong to exactly one commit. Default: one commit per phase, stage only the
   plan's directory, prefix `docs(manual)` for a manual and `docs` otherwise, allow a
   trace commit when a phase produces no changes.
6. **Notifications**: whether to use Telegram, another channel, or none. Default:
   Telegram through the `tg-telegram` skill, one message per completed phase plus start,
   block, and final messages.
7. **Subagents**: agent type and trust policy. Default: one `general` subagent per phase,
   foreground, sequential; trust the structured final status; do not review generated
   files; allow up to three build-fix subagents.
8. **Output**: language and delivery. Default language: the language of the user's
   request or the target manual. Default delivery: a fenced code block in chat. Offer to
   save to a file only if the user asks.

Present the resolved contract as a short table, for example:

| Setting | Value |
|---|---|
| Plan | `docs/manuals/cdss-operator/TASKS.md` |
| Scope | all phases |
| Build | `make -C docs/manuals/cdss-operator pdf` |
| Commit | one per phase; stage `docs/manuals/cdss-operator`; prefix `docs(manual)` |
| Notifications | Telegram via `tg-telegram` |
| Subagents | `general`, foreground, one per phase |
| Fix attempts | 3 |
| Language | Italian |
| Delivery | chat |

Ask the user to confirm or correct the table. Use `one per phase` or `multiple per
phase` in the Commit row; when multiple, record the grouping rule and the per-commit
message format. The contract is complete only when every material choice is explicit
and confirmed.

## 2. Generate the prompt

Write the prompt in the confirmed output language. Put it in one fenced code block.

The prompt must contain all of the following sections, adapted to the contract.

### Role and objective

Name the project and the plan. State that the orchestrator must complete the planned
phases, one at a time, by delegating each phase to a subagent. State that it must not
write the project itself.

### Inputs

List exact paths:

- plan file;
- specification, index, style guide, or other files the phase subagents must read;
- repository root;
- verification command;
- commit scope, shape, and message format;
- notification channel.

Do not invent paths. Use placeholders only for values the orchestrator must fill at
runtime.

### Non-negotiable rules

Include the user's contract and these defaults:

- one phase at a time, one subagent at a time, foreground only;
- exactly one subagent `general` per phase, with a fresh session;
- trust the subagent's structured final status; do not open, review, diff, or rewrite
  generated files;
- the only verification is the configured build/test command;
- on build failure, dispatch a dedicated fix subagent with the tail of the log; never
  fix the build manually; stop after the configured number of attempts;
- commit after each completed phase passes verification, using the configured commit
  shape (one commit or multiple focused commits) and staging only the configured scope;
- send a Telegram message after each completed phase, using the `tg-telegram` skill;
- do not push, amend, rebase, reset, clean, or rewrite history;
- do not modify application code, configuration, or fixtures unless the contract
  explicitly includes them;
- stop and notify if a phase is blocked, if the repository is not in a committable
  state, or if the work requires a scope outside the contract;
- keep the orchestrator's context small: read only phase headings, subagent status,
  the tail of build logs, and commit hashes. Do not read generated content.

### Preflight

Tell the orchestrator to:

1. Run `git status --short`; record unrelated changes and do not stage them.
2. Load the notification skill, run its status check, and ask the user to configure it
   if needed.
3. Extract phase headings from the plan without reading the full plan.
4. Confirm the phase count and scope.
5. Send a start notification.

### Phase loop

For each phase:

1. Build a subagent prompt from the template below, filled with the phase number,
   title, plan path, scope, and project-specific constraints.
2. Dispatch one `general` subagent in foreground with `background: false`.
3. Read only `STATUS`, `SUMMARY`, `FILES`, `CHECKS`, and `BLOCKER`, plus `COMMITS`
   when multiple commits are configured.
4. If `BLOCKED`, send the block notification and stop.
5. Run the configured build/test command.
6. If verification is not applicable, record that explicitly and continue.
7. If verification fails, dispatch the build-fix subagent, then rerun the verification.
8. If verification still fails after the allowed attempts, notify and stop.
9. Stage and commit the verified phase according to the configured commit policy:
   - one commit per phase: stage the configured scope and create one commit;
   - multiple commits per phase: validate that the subagent's `COMMITS` plan covers every
     changed path in scope before creating any commit. If it does, stage each group's
     explicit paths and create the commits in order; if it is missing or incomplete,
     create one phase commit from the configured scope and note the fallback in the
     notification.
10. Record every commit hash for the phase.
11. Send the phase-completion notification with the short commit hash or hashes and the
    next phase.
12. Start the next phase only after the notification.

### Commit policy

Specify the configured shape and its exact commands and guardrails.

**One commit per phase** (default):

- `git add -- <scope>` only; never `git add -A` or `git commit -a`;
- message format, for example
  `docs(manual): phase N — <phase title>`;
- empty/no-op commit behavior from the contract;
- no push;
- leave unrelated changes untouched and report them.

**Multiple commits per phase**:

- wait until the phase verification passes, then split the verified changes into the
  configured groups;
- use the phase subagent's `COMMITS` plan: each entry names a group label and the
  explicit paths for that commit;
- validate the plan before creating any commit: every changed path in scope must appear
  in exactly one group, and every path must be inside the configured scope;
- use `git status --short` only to check path coverage, not to inspect file contents;
- stage each group with `git add -- <paths>` and create the commits in the order the
  subagent reported;
- keep tests, fixtures, and docs with the code they describe; do not split one behavior
  change across commits;
- message format, for example
  `docs(manual): phase N — <phase title> — <group label>`;
- if the plan is missing or incomplete, create one commit for the whole phase with the
  phase-level message and record the fallback in the phase notification;
- no push; leave unrelated changes untouched and report them.

### Telegram protocol

Instruct the orchestrator to use the `tg-telegram` skill and `tg status` before the first
message. Include short templates for:

- start;
- phase completed, with the commit hash or hashes and the next phase;
- blocked phase, with reason and confirmation that no commit was created;
- final completion, with the PDF/build artifact and last commit hash.

If notification fails, retry once, record the failure, and continue unless the user
explicitly made notification a hard stop.

### Subagent phase prompt template

Include a template with:

- role: phase editor/implementer;
- exact phase number and title;
- files to read;
- tasks to complete;
- project-specific style, language, and safety constraints;
- instruction to update the plan/index checkboxes;
- instruction to run the checks required by the phase;
- instruction not to commit, not to send Telegram, not to spawn other agents, and not
  to modify out-of-scope code;
- when the multiple-commit policy is active, instruction to propose a `COMMITS` plan
  with one line per commit in the form `<group label> | <path>, <path>`, assigning every
  changed path to exactly one group and keeping tests with the code they cover;
- requirement to return only:
  `STATUS`, `SUMMARY`, `FILES`, `CHECKS`, `BLOCKER`, plus `COMMITS` when the
  multiple-commit policy is active.

### Build-fix subagent prompt template

Include a template with:

- the exact failing command;
- the last 80 lines of the log;
- permission to fix only compilation, references, assets, or environment issues;
- prohibition on rewriting content or changing application code;
- no commit and no notification;
- the same structured return format.

### Stop conditions

Repeat the block conditions:

- subagent `BLOCKED`;
- verification unrecoverable after the allowed fix attempts;
- out-of-scope changes;
- repository state prevents a clean commit;
- a phase requires modifying code outside the contract.

### Final report

Tell the orchestrator to report:

- phases completed;
- every commit hash and subject, grouped by phase;
- any fallback from multiple commits to one phase commit;
- verification results;
- notifications sent or failed;
- deliberately skipped phases or tasks;
- unresolved blockers.

## 3. Output

Return only:

1. a short confirmation of the contract;
2. the generated prompt in a fenced code block;
3. optional next-step note: paste the prompt into a fresh orchestrator session.

Do not execute the generated prompt. If the user asks you to execute it, explain that
this skill only builds the prompt and ask them to start an orchestrator agent with it.

## Example invocation

The user may invoke the skill directly with a short request such as:

`phase-orchestrator for the cdss-operator manual`

Resolve the plan, ask only the unresolved questions, confirm the contract, and produce
the prompt. Do not assume the project is CDSS Operator without checking the workspace.
