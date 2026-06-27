#!/bin/bash
# Run Lighthouse N times, take the median run, emit compact JSON.
# stderr = human logs, stdout = structured JSON (category scores + failing audits).
# Full Lighthouse reports are large; this keeps only what an agent needs to act.
set -euo pipefail

CATEGORIES_DEFAULT="performance,accessibility,seo,best-practices"

TMPDIR_RUN=""
cleanup() { [ -n "$TMPDIR_RUN" ] && rm -rf "$TMPDIR_RUN"; }
trap cleanup EXIT

fail() {
  local type="$1" msg="$2" suggestion="$3"
  if command -v jq >/dev/null 2>&1; then
    jq -n --arg type "$type" --arg msg "$msg" --arg suggestion "$suggestion" \
      '{success:false,error:{type:$type,message:$msg,suggestion:$suggestion,retryable:false}}'
  else
    printf '{"success":false,"error":{"type":"%s","message":"%s","suggestion":"%s"}}\n' \
      "$type" "$msg" "$suggestion"
  fi
  exit 1
}

command -v jq >/dev/null 2>&1 || fail "missing_dependency" "jq is required" "Install: brew install jq"
command -v npx >/dev/null 2>&1 || fail "missing_dependency" "Node/npx is required" "Install Node.js 18+"

[ $# -ge 1 ] || fail "invalid_input" "No URL provided" "Usage: $0 <url> [runs] [categories]"
URL="$1"
RUNS="${2:-3}"
CATEGORIES="${3:-$CATEGORIES_DEFAULT}"

case "$URL" in
  http://*|https://*) : ;;
  *) fail "invalid_input" "URL must start with http:// or https://" "Pass an absolute URL" ;;
esac
case "$RUNS" in
  ''|*[!0-9]*) fail "invalid_input" "runs must be a positive integer" "e.g. $0 $URL 3" ;;
esac

TMPDIR_RUN="$(mktemp -d)"

echo "Running Lighthouse $RUNS time(s) against $URL ..." >&2
declare -a SCORE_FILE_PAIRS=()
for i in $(seq 1 "$RUNS"); do
  out="$TMPDIR_RUN/run-$i.json"
  echo "  run $i/$RUNS ..." >&2
  if ! npx --yes lighthouse "$URL" \
        --quiet \
        --chrome-flags="--headless=new --no-sandbox" \
        --only-categories="$CATEGORIES" \
        --output=json --output-path="$out" >/dev/null 2>>"$TMPDIR_RUN/lh.log"; then
    echo "  run $i failed (see log below)" >&2
  fi
  if [ -s "$out" ]; then
    perf="$(jq -r '(.categories.performance.score // 0)' "$out" 2>/dev/null || echo 0)"
    SCORE_FILE_PAIRS+=("$perf|$out")
  fi
done

[ "${#SCORE_FILE_PAIRS[@]}" -ge 1 ] || \
  fail "lighthouse_failed" "No successful Lighthouse runs" "Check the URL is reachable; see Chrome/headless errors: $(tail -3 "$TMPDIR_RUN/lh.log" 2>/dev/null | tr '\n' ' ')"

# Pick the median run by performance score (Lighthouse's recommended variance fix).
IFS=$'\n' sorted=($(printf '%s\n' "${SCORE_FILE_PAIRS[@]}" | sort -t'|' -k1,1n))
unset IFS
median_index=$(( ${#sorted[@]} / 2 ))
MEDIAN_FILE="${sorted[$median_index]#*|}"
echo "Median run: $MEDIAN_FILE" >&2

jq -n \
  --arg url "$URL" \
  --argjson runs "${#SCORE_FILE_PAIRS[@]}" \
  --slurpfile lhr "$MEDIAN_FILE" \
  '($lhr[0]) as $r
   | {
       success: true,
       url: $url,
       runs: $runs,
       lighthouseVersion: ($r.lighthouseVersion // "unknown"),
       scores: (
         $r.categories
         | to_entries
         | map({ key: .key, value: ((.value.score // 0) * 100 | round) })
         | from_entries
       ),
       failingAudits: (
         [ $r.audits | to_entries[]
           | select(.value.score != null and .value.score < 0.9)
           | { id: .key, score: .value.score, displayValue: (.value.displayValue // "") } ]
         | sort_by(.score)
       )
     }'
