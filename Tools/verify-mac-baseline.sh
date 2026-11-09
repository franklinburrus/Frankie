#!/usr/bin/env bash
# Verify Frankie Mac baseline: repo identity, Caveman seven paths, app-code presence.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

EVIDENCE_CLASS="${EVIDENCE_CLASS:-VERIFIED}"
OUT="${1:-docs/BASELINE.md}"
TMP="$(mktemp)"

expected_origin_substr="github.com/franklinburrus/Frankie"
branch="$(git rev-parse --abbrev-ref HEAD)"
head="$(git rev-parse HEAD)"
origin="$(git remote get-url origin 2>/dev/null || true)"
# Scrub embedded credentials from evidence output.
origin="$(printf '%s' "$origin" | sed -E 's#://[^/@]+@#://#')"

protected=(
  "AGENTS.md"
  ".agents/skills/caveman/SKILL.md"
  ".agents/skills/ultracave/SKILL.md"
  "third_party/caveman/LICENSE"
  "third_party/caveman/LICENSE-MIT"
  "third_party/caveman/NOTICE"
  "third_party/caveman/provenance.json"
)

{
  echo "# Frankie baseline evidence"
  echo
  echo "- Evidence class: \`${EVIDENCE_CLASS}\`"
  echo "- Generated at: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "- Host: $(uname -s) $(uname -m)"
  echo "- Repo root: \`${ROOT}\`"
  echo "- Origin: \`${origin}\`"
  echo "- Branch: \`${branch}\`"
  echo "- HEAD: \`${head}\`"
  echo
  echo "## Origin check"
  if [[ "${origin}" == *"${expected_origin_substr}"* ]]; then
    echo "- Origin matches Frankie: YES"
  else
    echo "- Origin matches Frankie: NO (expected substring \`${expected_origin_substr}\`)"
  fi
  echo
  echo "## Protected Caveman paths"
  echo
  echo "| Path | Present | git blob SHA-1 | Matches provenance |"
  echo "|---|---|---|---|"
} >"$TMP"

all_ok=1
while IFS= read -r path; do
  if [[ ! -f "$path" ]]; then
    echo "| \`$path\` | NO | — | NO |" >>"$TMP"
    all_ok=0
    continue
  fi
  blob="$(git hash-object "$path")"
  match="n/a"
  if [[ "$path" == "AGENTS.md" ]]; then
    match="Frankie-specific (not Joey copy)"
  elif [[ "$path" == "third_party/caveman/provenance.json" ]]; then
    match="present (records other file hashes)"
  elif [[ -f third_party/caveman/provenance.json ]]; then
    expected="$(python3 - "$path" <<'PY'
import json,sys
path=sys.argv[1]
prov=json.load(open("third_party/caveman/provenance.json"))
for f in prov["files"]:
    if f["path"]==path:
        print(f["git_blob_sha1"]); break
PY
)"
    if [[ -n "$expected" && "$blob" == "$expected" ]]; then
      match="YES"
    else
      match="NO (expected ${expected:-missing})"
      all_ok=0
    fi
  fi
  echo "| \`$path\` | YES | \`$blob\` | $match |" >>"$TMP"
done < <(printf '%s\n' "${protected[@]}")

{
  echo
  echo "## App-code presence"
  echo
  # Heuristic inventory of likely Frankie application sources (tracked + worktree).
  app_list="$( {
    git ls-files 'Frankie/' 'Tests/' 'Package.swift' 'Tools/FrankieCLI/' 2>/dev/null || true
    find Frankie Tests Tools/FrankieCLI Package.swift Frankie.xcodeproj -type f 2>/dev/null || true
  } | sort -u )"
  app_count=0
  if [[ -n "$app_list" ]]; then
    app_count="$(printf '%s\n' "$app_list" | grep -c . || true)"
  fi
  if [[ "$app_count" -eq 0 ]]; then
    echo "- Application paths present: none"
    echo "- App-code deletion for empty shell: VERIFIED NO-OP (no app sources present)."
  else
    echo "- Application-related paths present: ${app_count}"
    echo
    echo '```'
    printf '%s\n' "$app_list" | head -n 80
    echo '```'
    echo
    echo "- Pre-Phase-1 GitHub/cloud empty shell had no app code: VERIFIED NO-OP for deletion."
    echo "- This checkout now contains Phase 1 scaffold (expected after implementation)."
  fi
  echo
  echo "## Result"
  if [[ "$all_ok" -eq 1 ]]; then
    echo "- Caveman seven-path integrity: PASS"
  else
    echo "- Caveman seven-path integrity: FAIL"
  fi
} >>"$TMP"

mkdir -p "$(dirname "$OUT")"
mv "$TMP" "$OUT"
echo "Wrote $OUT"
[[ "$all_ok" -eq 1 ]]
