# Skills

A portable collection of my OpenCode skills. Each skill is a folder with a `SKILL.md`; `grill-me-gui` also carries its HTML template and builder script.

## Skills

| Skill | Invocation | What it does |
|---|---|---|
| [`commit`](skills/commit/SKILL.md) | model-invoked | Creates focused git commits from the current work, using the conversation as context. |
| [`phase-orchestrator`](skills/phase-orchestrator/SKILL.md) | user-invoked | Builds a ready-to-paste prompt for an orchestrator that runs a phased plan. |
| [`tg-telegram`](skills/tg-telegram/SKILL.md) | model-invoked | Sends and receives Telegram messages through the `tg` CLI. |
| [`grill-me-gui`](skills/grill-me-gui/SKILL.md) | user-invoked | Runs the relentless `grilling` interview, but delivers each round as a local static web page with a copy-answers button. |

## Install

OpenCode loads user skills from either:

- `~/.config/opencode/skills/`
- `~/.agents/skills/`

Pick one root per machine. Don't install the same skill into both, or OpenCode may see duplicate names.

### Automatic

```bash
git clone https://github.com/galatolofederico/skills.git
cd skills
./install.sh
```

The installer defaults to `~/.config/opencode/skills` and skips any skill already present in either root. To choose the other root:

```bash
./install.sh ~/.agents/skills
```

To replace existing copies in the destination:

```bash
./install.sh --force
```

`--force` only replaces the matching folders in the destination; it does not touch the other root. If the same name exists in both roots, remove the unwanted copy.

### Manual

```bash
git clone https://github.com/galatolofederico/skills.git
cp -R skills/skills/* ~/.config/opencode/skills/
```

Or copy just one:

```bash
cp -R skills/skills/grill-me-gui ~/.config/opencode/skills/
```

OpenCode reloads skill directories automatically; if a picker was already open, reopen it.

## Requirements

- `commit` — `git` in `PATH`.
- `tg-telegram` — the `tg` CLI in `PATH`, plus `curl` and `jq`. Run `tg init` once to create `~/.tg.conf`.
- `phase-orchestrator` — no extra tooling; its generated prompt can use `tg-telegram` for notifications.
- `grill-me-gui` — Python 3 and a browser. The generated pages are static and need no server. It also uses the `grilling` skill from `mattpocock/skills`; install that separately if it is not already available.

## Invocation

`commit` and `tg-telegram` are model-invoked, so the agent can reach for them when the task matches. `phase-orchestrator` and `grill-me-gui` are user-invoked: invoke them explicitly by name.

## Updating

```bash
cd skills
git pull
./install.sh --force
```

## Notes

- Skills are plain text. Keep secrets out of them; `tg-telegram` reads its bot token from `~/.tg.conf`, not from this repo.
- The installer copies files. It does not create symlinks, so moving or deleting the clone later does not break the installed skills.
