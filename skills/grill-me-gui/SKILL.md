---
name: grill-me-gui
description: A relentless interview to sharpen a plan or design, answered in a local web page.
disable-model-invocation: true
---

# Grill Me (GUI)

Run the same interview as `grill-me`, but deliver each round as a local web page. The user answers in the browser and pastes one copied block back into OpenCode.

## Start the interview

Call the Skill tool with `"grilling"`. Work its design tree and compute the frontier exactly as that skill describes. Where `/grilling` says to format the round in chat, put the round on the page instead. The interview itself is unchanged.

## Build a round page

Keep one session directory for the whole interview:

```bash
mkdir -p /tmp/opencode/grill-me-gui
SESSION_DIR="$(mktemp -d /tmp/opencode/grill-me-gui/grill.XXXXXX)"
```

Write the whole frontier for the round to `"$SESSION_DIR/round-1.json"`:

```json
{
  "topic": "Designing offline sync",
  "round": 1,
  "intro": "One or two sentences that bring the user back into this round.",
  "questions": [
    {
      "title": "Where does the queue live?",
      "body": "The app must work offline and sync later.\n\n- **IndexedDB** keeps v1 web-only.\n- **A local SQLite file** pulls in a desktop wrapper.\n\nWhich constraint wins?",
      "recommendation": "Start with IndexedDB. The sync layer can treat it as an adapter later.",
      "options": ["IndexedDB", "Local SQLite file"]
    }
  ]
}
```

Build it with the bundled script. Set `SKILL_DIR` to this skill's base directory; the skill loader prints the exact path when the skill loads. It is normally one of these:

```bash
SKILL_DIR="$HOME/.config/opencode/skills/grill-me-gui"
# or
SKILL_DIR="$HOME/.agents/skills/grill-me-gui"

python3 "$SKILL_DIR/scripts/build_page.py" "$SESSION_DIR/round-1.json"
```

The script prints `Built:` and `Open:`. The `Open:` line is the `file://` URL to hand over.

## Hand over the link

Give the user a Markdown link and the plain path:

```
Round 1 is ready: [open the questions](file:///tmp/opencode/grill-me-gui/grill.abc123/round-1.html)

Plain path: `/tmp/opencode/grill-me-gui/grill.abc123/round-1.html`
```

Then wait. The page shows your recommended answers, turns choices into buttons, saves answers in the browser, and has a **Copy answers** button at the bottom.

Deliver the questions on the page; keep chat to the link and a one-line status. Do not open the browser unless the user asks. The page is the delivery surface; the JSON is the durable record. If the user's terminal does not make `file://` links clickable, tell them to run `xdg-open <plain path>` (or `open` on macOS).

## Read the answers

The copy button produces:

```markdown
# Grill Me — Round 1 answers

**Topic:** Designing offline sync

## Q1 — Where does the queue live?

Yes — go with your recommendation.
```

Rules:

- `## Q<n> — <title>` is the answer to Q<n> of that round.
- `Yes — go with your recommendation.` means the user accepts your recommendation for that question.
- `_(unanswered)_` means it is still open. Never treat an unanswered question as agreement.
- If the user pastes prose, or answers in chat instead, accept that too.

Then update the design tree, recompute the frontier, and build the next round in the same `SESSION_DIR`. Keep the JSON files: they are the record of what was asked and answered.

## Finish

Stop when the frontier is empty. Write the shared understanding in chat and ask the user to confirm it. Do not act on it before they confirm.

## Round data

Fields:

- `topic` — the subject being grilled. Required.
- `round` — positive integer, starting at 1. Required.
- `intro` — context shown under the title. Optional.
- `questions[].title` — short and declarative. Required.
- `questions[].body` — the argument, constraints, and choices. Supports blank-line paragraphs, `- ` or `1. ` lists, `**bold**`, and `` `code` ``. Rendered as text, never raw HTML.
- `questions[].recommendation` — your recommended answer, in the imperative, phrased so accepting it is a complete answer. Required. Inline `**bold**` and `` `code` `` work here too.
- `questions[].options` — optional list of strings. Each becomes a button that fills the answer with that choice.
- `questions[].placeholder` — optional textarea placeholder.

Ask the **whole frontier in one round**, not one question per page. Keep round titles short; put the reasoning in `body`. Never put secrets or personal data in the JSON: the page is local, but the files are plain text.

The bundled `assets/example.json` is a complete round you can inspect or build.

## Notes

- The page is static: no server, no network requests, no telemetry. Answers autosave in the browser's `localStorage`, keyed by the page path, so a reload does not lose them.
- One page per round. Old pages remain answerable. Do not overwrite a page the user may have answered; if you must rebuild, use a new filename such as `round-2-v2.html`.
- `assets/grill.html` is also a working preview: open it directly to see the UI with sample questions.
- If you lose the round data, re-read the JSON file instead of reconstructing it from memory.
