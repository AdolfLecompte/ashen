#!/usr/bin/env bash
# The Settings search index must match the rows that exist.
cd "$(dirname "$0")/../.."
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
scripts/ashen-settings-index.sh "$tmp"
if cmp -s "$tmp" quickshell/.config/quickshell/ashen/modules/settings/SearchIndex.js; then
    echo "ok   SearchIndex.js is current"
else
    echo "FAIL SearchIndex.js is stale: run scripts/ashen-settings-index.sh"; exit 1
fi
n=$(grep -c '^    \["' "$tmp")
if [ "$n" -gt 100 ]; then echo "ok   index holds $n rows"
else echo "FAIL index holds only $n rows"; exit 1; fi
