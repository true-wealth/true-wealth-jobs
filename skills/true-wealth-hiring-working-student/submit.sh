#!/usr/bin/env bash
# Submits a True Wealth job application to the webhook defined in $WEBHOOK.
# Runs anywhere bash + curl are available (Linux, macOS, Git Bash / WSL on Windows).

set -u

WEBHOOK="https://hooks.attio.com/w/aee3ff3a-463d-4856-b656-e378f340b657/3ec45794-6269-455e-9d5b-573139db0d04"

name=""
email=""
most_recent_degree=""
motivation=""
swiss_work_permit=""
profile_url=""

die() { printf 'Error: %s\n' "$1" >&2; exit 1; }

while [ $# -gt 0 ]; do
    case "$1" in
        --name)                name=$2;                shift 2 ;;
        --email)               email=$2;               shift 2 ;;
        --most_recent_degree)  most_recent_degree=$2;  shift 2 ;;
        --motivation)          motivation=$2;          shift 2 ;;
        --swiss_work_permit)   swiss_work_permit=$2;   shift 2 ;;
        --profile_url)        profile_url=$2;        shift 2 ;;
        *) die "unknown argument: $1" ;;
    esac
done

[ -n "$name" ]                || die "--name is required and must be non-empty."
[ -n "$email" ]               || die "--email is required and must be non-empty."
[ -n "$most_recent_degree" ]  || die "--most_recent_degree is required and must be non-empty."
[ -n "$swiss_work_permit" ]   || die "--swiss_work_permit is required and must be non-empty."

case "$swiss_work_permit" in
    true|false) ;;
    *) die "--swiss_work_permit must be 'true' or 'false' (got: $swiss_work_permit)" ;;
esac

# JSON-escape a string for safe embedding in the payload.
json_escape() {
    local s=$1
    s=${s//\\/\\\\}
    s=${s//\"/\\\"}
    s=${s//$'\n'/\\n}
    s=${s//$'\r'/\\r}
    s=${s//$'\t'/\\t}
    printf '%s' "$s"
}

payload=$(printf '{"name":"%s","email":"%s","most_recent_degree":"%s","motivation":"%s","swiss_work_permit":%s,"profile_url":"%s"}' \
    "$(json_escape "$name")" \
    "$(json_escape "$email")" \
    "$(json_escape "$most_recent_degree")" \
    "$(json_escape "$motivation")" \
    "$swiss_work_permit" \
    "$(json_escape "$profile_url")")

resp_file=$(mktemp -t tw_apply_resp.XXXXXX) || die "could not create temp file."
trap 'rm -f "$resp_file"' EXIT

http_code=$(curl -sS -o "$resp_file" -w '%{http_code}' \
    -X POST "$WEBHOOK" \
    -H 'Content-Type: application/json' \
    --data-binary "$payload") || die "network error while submitting application."

body=$(cat "$resp_file" 2>/dev/null || true)

if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 300 ]; then
    printf 'OK (HTTP %s)\n' "$http_code"
    exit 0
fi

printf 'Submission failed (HTTP %s)\n%s\n' "$http_code" "$body" >&2
exit 1
