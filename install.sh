#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source_dir="$repo_dir/skills"
dest="$HOME/.config/opencode/skills"
force=0

usage() {
  cat <<'EOF'
Usage: ./install.sh [--force] [DEST]

Copy the skills in ./skills into DEST (default: ~/.config/opencode/skills)
and install bin/tg to ~/.local/bin/tg.

Options:
  --force      Update skills already installed in either known root, and
               replace the tg binary.
  -h, --help   Show this help.
EOF
}

for arg in "$@"; do
  case "$arg" in
    --force)
      force=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      dest="$arg"
      ;;
  esac
done

if [ ! -d "$source_dir" ]; then
  echo "error: no skills directory next to this script" >&2
  exit 1
fi

mkdir -p "$dest"
dest="$(cd "$dest" && pwd)"

if [ "$dest" = "$source_dir" ]; then
  echo "error: destination must not be the repository's own skills directory" >&2
  exit 1
fi

normalize_dir() {
  if [ -d "$1" ]; then
    (cd "$1" && pwd)
  else
    printf '%s\n' "$1"
  fi
}

known_roots=("$HOME/.config/opencode/skills" "$HOME/.agents/skills")

for skill_dir in "$source_dir"/*/; do
  [ -d "$skill_dir" ] || continue
  name="$(basename "$skill_dir")"
  destination="$dest/$name"

  duplicate=""
  for root in "${known_roots[@]}"; do
    root="$(normalize_dir "$root")"
    if [ "$root" != "$dest" ] && [ -e "$root/$name" ]; then
      duplicate="$root/$name"
      break
    fi
  done

  if [ -e "$destination" ] && [ -n "$duplicate" ]; then
    echo "error: $name exists in both $destination and $duplicate; remove one copy before installing" >&2
    continue
  fi

  if [ -e "$destination" ]; then
    if [ "$force" -ne 1 ]; then
      echo "skip $name: already installed at $destination (use --force to update)"
      continue
    fi
    rm -rf "$destination"
    cp -R "$skill_dir" "$destination"
    echo "updated $name -> $destination"
    continue
  fi

  if [ -n "$duplicate" ]; then
    if [ "$force" -ne 1 ]; then
      echo "skip $name: already installed at $duplicate (use --force to update it there)"
      continue
    fi
    rm -rf "$duplicate"
    cp -R "$skill_dir" "$duplicate"
    echo "updated $name -> $duplicate (existing installation root)"
    continue
  fi

  cp -R "$skill_dir" "$destination"
  echo "installed $name -> $destination"
done

tg_source="$repo_dir/bin/tg"
tg_dest="$HOME/.local/bin/tg"

if [ -f "$tg_source" ]; then
  if [ -e "$tg_dest" ] && [ "$force" -ne 1 ]; then
    echo "skip tg: already installed at $tg_dest (use --force to replace)"
  else
    if [ -e "$tg_dest" ]; then
      action="updated"
    else
      action="installed"
    fi
    mkdir -p "$(dirname "$tg_dest")"
    install -m 755 "$tg_source" "$tg_dest"
    echo "$action tg -> $tg_dest"
  fi

  case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) echo "warning: $HOME/.local/bin is not in PATH; add it to use tg" >&2 ;;
  esac

  existing_tg="$(type -P tg 2>/dev/null || true)"
  if [ -n "$existing_tg" ] && [ "$existing_tg" != "$tg_dest" ]; then
    echo "warning: another tg is already in PATH at $existing_tg" >&2
  fi
else
  echo "warning: bin/tg not found; skipping the Telegram CLI" >&2
fi

echo
echo "Done. OpenCode reloads skills automatically."
