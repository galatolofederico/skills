#!/usr/bin/env python3
"""Build a static grill-me-gui round page from a JSON question set.

Usage:
    python3 build_page.py round-1.json
    python3 build_page.py round-1.json --out /tmp/opencode/grill-me-gui/round-1.html

The template lives at ../assets/grill.html, next to this script's parent.
The finished page is fully self-contained: no server, no network requests.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any, NoReturn

SKILL_DIR = Path(__file__).resolve().parent.parent
DEFAULT_TEMPLATE = SKILL_DIR / "assets" / "grill.html"
DATA_SCRIPT_MARKER = 'id="grill-data"'


def fail(message: str) -> NoReturn:
    print(f"error: {message}", file=sys.stderr)
    raise SystemExit(1)


def load_round(path: Path) -> dict[str, Any]:
    try:
        raw = path.read_text(encoding="utf-8")
    except OSError as exc:
        fail(f"cannot read {path}: {exc}")

    try:
        data = json.loads(raw)
    except json.JSONDecodeError as exc:
        fail(f"{path} is not valid JSON: {exc}")

    if not isinstance(data, dict):
        fail("the round file must contain a JSON object")

    topic = data.get("topic")
    if not isinstance(topic, str) or not topic.strip():
        fail("`topic` must be a non-empty string")

    round_number = data.get("round", 1)
    if isinstance(round_number, bool) or not isinstance(round_number, int) or round_number < 1:
        fail("`round` must be a positive integer")

    intro = data.get("intro", "")
    if not isinstance(intro, str):
        fail("`intro` must be a string")

    questions = data.get("questions")
    if not isinstance(questions, list) or not questions:
        fail("`questions` must be a non-empty array")

    normalized_questions: list[dict[str, Any]] = []
    for index, question in enumerate(questions, start=1):
        if not isinstance(question, dict):
            fail(f"question {index} must be an object")

        title = question.get("title")
        if not isinstance(title, str) or not title.strip():
            fail(f"question {index} needs a non-empty `title`")

        body = question.get("body", "")
        if isinstance(body, list):
            body = "\n\n".join(str(part) for part in body)
        if not isinstance(body, str):
            fail(f"question {index} `body` must be a string")

        recommendation = question.get("recommendation")
        if not isinstance(recommendation, str) or not recommendation.strip():
            fail(f"question {index} needs a non-empty `recommendation`")

        options = question.get("options", [])
        if options is None:
            options = []
        if not isinstance(options, list) or any(not isinstance(option, str) for option in options):
            fail(f"question {index} `options` must be an array of strings")

        placeholder = question.get("placeholder", "Type your answer…")
        if not isinstance(placeholder, str):
            fail(f"question {index} `placeholder` must be a string")

        normalized_questions.append(
            {
                "title": title.strip(),
                "body": body.strip(),
                "recommendation": recommendation.strip(),
                "options": [option.strip() for option in options if option.strip()],
                "placeholder": placeholder,
            }
        )

    return {
        "topic": topic.strip(),
        "round": round_number,
        "intro": intro.strip(),
        "questions": normalized_questions,
    }


def inject_questions(template: str, data: dict[str, Any]) -> str:
    marker_start = template.find(DATA_SCRIPT_MARKER)
    if marker_start == -1:
        fail(f"template is missing the {DATA_SCRIPT_MARKER} script tag")

    open_tag_end = template.find(">", marker_start)
    if open_tag_end == -1:
        fail("template has a malformed data script tag")

    close_tag_start = template.find("</script>", open_tag_end)
    if close_tag_start == -1:
        fail("template has an unclosed data script tag")

    # JSON is valid inside a script tag, but `</script>` would close the tag.
    payload = json.dumps(data, ensure_ascii=False, indent=2).replace("</", "<\\/")
    return template[: open_tag_end + 1] + "\n" + payload + "\n" + template[close_tag_start:]


def build_page(questions_path: Path, output_path: Path, template_path: Path) -> None:
    if output_path.resolve() == template_path.resolve():
        fail("refusing to overwrite the template; choose a different output path")

    try:
        template = template_path.read_text(encoding="utf-8")
    except OSError as exc:
        fail(f"cannot read template {template_path}: {exc}")

    data = load_round(questions_path)
    page = inject_questions(template, data)

    try:
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(page, encoding="utf-8")
    except OSError as exc:
        fail(f"cannot write {output_path}: {exc}")

    resolved = output_path.resolve()
    print(f"Built: {resolved}")
    print(f"Open:  {resolved.as_uri()}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Build a self-contained grill-me-gui round page from JSON."
    )
    parser.add_argument(
        "questions",
        type=Path,
        help="path to the round JSON file",
    )
    parser.add_argument(
        "-o",
        "--out",
        type=Path,
        default=None,
        help="output HTML path (default: the JSON path with an .html suffix)",
    )
    parser.add_argument(
        "-t",
        "--template",
        type=Path,
        default=DEFAULT_TEMPLATE,
        help="template HTML path (default: the bundled assets/grill.html)",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    output_path = args.out or args.questions.with_suffix(".html")
    build_page(args.questions, output_path, args.template)


if __name__ == "__main__":
    main()
