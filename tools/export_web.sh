#!/bin/sh
set -eu
trivia_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
trivia_godot=${GODOT_BIN:-godot}
mkdir -p "$trivia_root/builds/web"
"$trivia_godot" --headless --path "$trivia_root/game" --export-release Web "$trivia_root/builds/web/index.html"

cp -R "$trivia_root/bank" "$trivia_root/builds/web/"
