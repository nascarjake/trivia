#!/bin/sh
set -eu
trivia_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
trivia_godot=${GODOT_BIN:-godot}
mkdir -p "$trivia_root/builds/pages"
"$trivia_godot" --headless --path "$trivia_root/game" --export-release "GitHub Pages" "$trivia_root/builds/pages/index.html"
: > "$trivia_root/builds/pages/.nojekyll"
