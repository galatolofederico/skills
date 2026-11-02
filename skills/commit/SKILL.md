---
name: Commit
description: Use when the user asks to commit changes or runs /commit: inspect the working tree, commit exactly the staged set as one commit, or split unstaged work into meaningful focused commits by staging each part, with messages built from the conversation.
---

# Commit

Create commits from the current work. Use the conversation history to understand what changed and why, not just the diff.

The shape of the commit history depends on the index:

- **Staged files exist**: make **exactly one commit** from that staged set.
- **Nothing staged**: stage and commit in one or more focused commits when the work naturally splits; otherwise make a single commit.

## 1. Inspect

Run and read:

```sh
git rev-parse --show-toplevel   # stop if this fails
git status --short
git diff --cached --stat
git diff --cached
git diff --stat
git diff
git log -8 --oneline
```

Read `AGENTS.md` or `CONTRIBUTING.md` when present for commit and testing conventions.

From the conversation, establish what the user asked for, which files implement it, and why. That understanding drives the messages.

Done when every modified, staged, and untracked path is accounted for as either part of a commit or deliberately excluded.

## 2. Decide the commit shape

Check the index first.

### Staged files exist

Commit **exactly that set as one commit**. Leave other changes alone. Do not split it, and do not stage additional files unless the user asks.

If the staged set mixes unrelated work, note that in the report instead of splitting it.

### Nothing staged

The whole working tree is yours to organize. Prefer multiple commits when the changes decompose into independent, coherent units; otherwise make one.

A split is meaningful when each commit:

- covers one concern (feature, fix, refactor, docs, tooling) that stands on its own;
- could be reviewed, reverted, and understood in isolation;
- keeps its tests and docs with the code they describe.

Do not split artificially: don't separate tests from the code they test, a rename from its call-site updates, or mechanical churn from the change that caused it. If ordering matters, commit foundations first so each intermediate state is coherent.

Stage each commit separately with explicit paths or hunks:

```sh
git add -- path...             # whole files
git add -p -- path...          # part of a file, hunk by hunk
git add -N -- path             # then git add -p for a new file
```

Leave unrelated work, generated output, dependencies, binaries, and local environment or credential files out.

If the intended split or file set is ambiguous, show `git status --short` and ask.

Done when the plan covers every path and each planned commit is coherent on its own.

## 3. Message

Follow the repository's style from `git log` and its contributing docs. Otherwise use Conventional Commits:

```text
type(scope): imperative summary under ~72 characters

Explain the problem and why this approach. Draw on the conversation for
intent and issue references. Wrap the body near 72 columns.
```

Types: `feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `build`, `ci`, `chore`, `style`.

The subject names the outcome, not the files. The body says what and why; the diff already says how. Mention tests only when they were actually run. Write every message from the conversation, not from the diff alone.

## 4. Commit

Pass each message through stdin so formatting survives:

```sh
git commit -F - <<'EOF'
type(scope): summary

Body.
EOF
```

With multiple commits, repeat stage → message → commit for each one, in the planned order. Do not leave the index with a half-staged state between commits.

If a hook fails, fix the reported issue and retry. Report a failure you cannot fix instead of bypassing it.

Done when `git log` shows every planned commit and the only remaining changes are those deliberately excluded.

## 5. Report

Give each commit hash and subject in order, the files in each, and anything deliberately left uncommitted with a one-line reason. Check `git status --short` afterward so the report matches reality.

## Guardrails

- Never stage secrets, credentials, or `.env` files. If one is already staged, stop and warn.
- Never modify files just to produce a commit.
- With staged files present, make exactly one commit and do not split it.
- Never amend, rebase, force-push, or tag unless the user asks.
- Never rewrite history you have already committed during this run; add a follow-up commit instead if something was missed.
- During a merge or rebase, or with unresolved conflicts, stop and report the state.
- Nothing to commit: say so and skip the empty commit.
- Detached HEAD is fine to commit on; mention it in the report.
