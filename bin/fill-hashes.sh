#!/usr/bin/env bash

set -euo pipefail
cd "$(dirname "$0")/.."

for lang in $(nix eval --json .#lib.pins --apply 'builtins.attrNames' | jq -r '.[]'); do
    pin=$(nix eval --json ".#lib.pins.$lang")
    owner=$(jq -r '.owner // ""' <<<"$pin")
    repo=$(jq -r '.repo // ""' <<<"$pin")
    rev=$(jq -r '.rev // ""' <<<"$pin")
    location=$(jq -r '.location // ""' <<<"$pin")

    info=$(nix flake prefetch "github:$owner/$repo/$rev" --json)
    hash=$(jq -r '.hash' <<<"$info")
    tree=$(jq -r '.storePath' <<<"$info")

    parser="$tree/${location:+$location/}src/parser.c"
    if [ ! -f "$parser" ]; then
        echo "FAIL: $lang: $parser is missing, check owner/repo/rev/location" >&2
        exit 1
    fi

    sed -i -E "/^\s*${lang} = \{/,/^\s*\};/ s|hash = \"[^\"]*\"|hash = \"${hash}\"|" pins.nix
    echo "$lang ($owner/$repo@$rev) →  $hash"
done
