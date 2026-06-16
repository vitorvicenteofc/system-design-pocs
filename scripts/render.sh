#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FORMAT="${PLANTUML_FORMAT:-svg}"

if ! command -v docker &>/dev/null; then
  echo "Error: docker is required but not found on PATH." >&2
  exit 1
fi

render_design() {
  local slug="$1"
  local design_dir="$REPO_ROOT/designs/$slug"

  if [[ ! -d "$design_dir" ]]; then
    echo "Error: design folder not found: designs/$slug" >&2
    exit 1
  fi

  shopt -s nullglob
  local puml_files=("$design_dir"/*.puml)
  shopt -u nullglob

  if [[ ${#puml_files[@]} -eq 0 ]]; then
    echo "No .puml files in designs/$slug" >&2
    exit 1
  fi

  mkdir -p "$design_dir/diagrams"

  local docker_args=()
  for puml_file in "${puml_files[@]}"; do
    docker_args+=("/data/designs/$slug/$(basename "$puml_file")")
  done

  echo "Rendering designs/$slug (${#puml_files[@]} file(s)) -> designs/$slug/diagrams/"
  docker run --rm -v "$REPO_ROOT:/data" plantuml/plantuml "-t$FORMAT" -o diagrams "${docker_args[@]}"
}

if [[ $# -eq 0 ]]; then
  found=0
  for design_dir in "$REPO_ROOT/designs"/*/; do
    [[ -d "$design_dir" ]] || continue
    slug="$(basename "$design_dir")"
    shopt -s nullglob
    puml_files=("$design_dir"*.puml)
    shopt -u nullglob
    if [[ ${#puml_files[@]} -gt 0 ]]; then
      render_design "$slug"
      found=1
    fi
  done
  if [[ "$found" -eq 0 ]]; then
    echo "No .puml files found under designs/" >&2
    exit 1
  fi
else
  render_design "$1"
fi
