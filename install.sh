#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source_dir="$repo_dir/skills"
dest="$HOME/.config/opencode/skills"
force=0

usage() {
  cat <<'EOF'
Usage: ./install.sh [--force] [DEST]

Copy the skills in ./skills into DEST (default: ~/.config/opencode/skills).

Options:
  --force      Replace skills already present in DEST.
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

  if [ -e "$destination" ] && [ "$force" -ne 1 ]; then
    echo "skip $name: already installed at $destination (use --force to replace)"
    continue
  fi

  duplicate=""
  for root in "${known_roots[@]}"; do
    root="$(normalize_dir "$root")"
    if [ "$root" != "$dest" ] && [ -e "$root/$name" ]; then
      duplicate="$root/$name"
      break
    fi
  done

  if [ -n "$duplicate" ] && [ "$force" -ne 1 ]; then
    echo "skip $name: already installed at $duplicate (use --force to install a second copy)"
    continue
  fi

  if [ -n "$duplicate" ]; then
    echo "warning: $name also exists at $duplicate; installing another copy may create a duplicate skill name" >&2
  fi

  if [ -e "$destination" ]; then
    rm -rf "$destination"
  fi
  cp -R "$skill_dir" "$destination"
  echo "installed $name -> $destination"
done

echo
echo "Done. OpenCode reloads skills automatically."
