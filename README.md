# Skills

A portable collection of my OpenCode skills. Each skill is a folder with a `SKILL.md`; `grill-me-gui` also carries its HTML template and builder script.

## Repo layout

```text
.
├── README.md
├── install.sh
├── bin/
│   └── tg
└── skills/
    ├── commit/
    ├── phase-orchestrator/
    ├── tg-telegram/
    └── grill-me-gui/
```

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

The installer copies the four skills into `~/.config/opencode/skills` by default, installs the `tg` CLI to `~/.local/bin/tg` when it is not already there, and skips any skill already present in either skill root. To choose the other skill root:

```bash
./install.sh ~/.agents/skills
```

To update existing copies in place and refresh `~/.local/bin/tg`:

```bash
./install.sh --force
```

`--force` updates each skill wherever it is already installed in the two known roots, and refreshes the `tg` binary. If a skill exists in both roots, the installer stops with an error; remove the unwanted copy first.

### Manual

```bash
git clone https://github.com/galatolofederico/skills.git
mkdir -p ~/.config/opencode/skills ~/.local/bin
cp -R skills/skills/* ~/.config/opencode/skills/
install -m 755 bin/tg ~/.local/bin/tg
```

Or copy just one skill:

```bash
mkdir -p ~/.config/opencode/skills
cp -R skills/skills/grill-me-gui ~/.config/opencode/skills/
```

OpenCode reloads skill directories automatically; if a picker was already open, reopen it.

### Telegram CLI

`tg-telegram` expects the `tg` command in `PATH`. The installer copies `bin/tg` to `~/.local/bin/tg` when it is not already present. To install it manually:

```bash
mkdir -p ~/.local/bin
install -m 755 bin/tg ~/.local/bin/tg
```

Make sure `~/.local/bin` is in `PATH`. Then run `tg init` once; it stores the bot token and chat ID in `~/.tg.conf` on that machine.

## Requirements

- `commit` — `git` in `PATH`.
- `tg-telegram` — `tg` in `PATH` (installed by `install.sh`), plus `curl` and `jq`. Run `tg init` once to create `~/.tg.conf`.
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

- Skills and the `tg` script are plain text. No bot token, chat ID, or `~/.tg.conf` content is stored in this repo: `tg init` writes those only to `~/.tg.conf` on the local machine.
- The installer copies files. It does not create symlinks, so moving or deleting the clone later does not break the installed skills or the `tg` command.
