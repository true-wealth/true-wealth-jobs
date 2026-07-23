#!/usr/bin/env bash
# Submits a True Wealth job application (Digital Marketing Manager interim, VAC-04)
# to the webhook defined in $WEBHOOK.
# Runs anywhere bash + curl are available (Linux, macOS, Git Bash / WSL on Windows).

set -u

WEBHOOK="https://hooks.attio.com/w/aee3ff3a-463d-4856-b656-e378f340b657/72fc5059-d3ca-4dd1-9647-f7c861c57661"
POSITION_CODE="VAC-04"
# Attio Select option ID for "Applicant AI Chat" — fixed for this public flow.
SOURCE_OPTION_ID="94f0bbec-c71c-4694-856e-4a42bc215a6c"

# Attio caps the resume field at 1,000,000 bytes of base64, i.e. ~750 KB of raw
# PDF. We enforce the raw limit here and re-check the encoded size below.
MAX_PDF_BYTES=750000
MAX_B64_BYTES=1000000

first_name=""
last_name=""
full_name=""
email=""
phone=""
swiss_work_permit=""
linkedin_url=""
address_street=""
address_city=""
address_postal_code=""
address_country=""
earliest_availability=""
desired_comp_min_chf=""
desired_comp_max_chf=""
application_markdown=""
resume_pdf=""

die() { printf 'Error: %s\n' "$1" >&2; exit 1; }

while [ $# -gt 0 ]; do
    case "$1" in
        --first_name)            first_name=$2;            shift 2 ;;
        --last_name)             last_name=$2;             shift 2 ;;
        --full_name)             full_name=$2;             shift 2 ;;
        --email)                 email=$2;                 shift 2 ;;
        --phone)                 phone=$2;                 shift 2 ;;
        --swiss_work_permit)     swiss_work_permit=$2;     shift 2 ;;
        --linkedin_url)          linkedin_url=$2;          shift 2 ;;
        --address_street)        address_street=$2;        shift 2 ;;
        --address_city)          address_city=$2;          shift 2 ;;
        --address_postal_code)   address_postal_code=$2;   shift 2 ;;
        --address_country)       address_country=$2;       shift 2 ;;
        --earliest_availability) earliest_availability=$2; shift 2 ;;
        --desired_comp_min_chf)  desired_comp_min_chf=$2;  shift 2 ;;
        --desired_comp_max_chf)  desired_comp_max_chf=$2;  shift 2 ;;
        --application_markdown)  application_markdown=$2;  shift 2 ;;
        --resume_pdf)            resume_pdf=$2;            shift 2 ;;
        *) die "unknown argument: $1" ;;
    esac
done

[ -n "$first_name" ]           || die "--first_name is required and must be non-empty."
[ -n "$last_name" ]            || die "--last_name is required and must be non-empty."
[ -n "$full_name" ]            || die "--full_name is required and must be non-empty."
[ -n "$email" ]                || die "--email is required and must be non-empty."
[ -n "$phone" ]                || die "--phone is required and must be non-empty."
[ -n "$swiss_work_permit" ]    || die "--swiss_work_permit is required and must be non-empty."
[ -n "$address_street" ]       || die "--address_street is required and must be non-empty."
[ -n "$address_city" ]         || die "--address_city is required and must be non-empty."
[ -n "$address_postal_code" ]  || die "--address_postal_code is required and must be non-empty."
[ -n "$address_country" ]      || die "--address_country is required and must be non-empty."
[ -n "$application_markdown" ] || die "--application_markdown is required and must be non-empty."

case "$swiss_work_permit" in
    true|false) ;;
    *) die "--swiss_work_permit must be 'true' or 'false' (got: $swiss_work_permit)" ;;
esac

if [ -n "$earliest_availability" ]; then
    case "$earliest_availability" in
        [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;;
        *) die "--earliest_availability must be YYYY-MM-DD (got: $earliest_availability)" ;;
    esac
fi

is_number() { case "$1" in ''|*[!0-9.]*|*.*.*) return 1 ;; *) return 0 ;; esac; }
if [ -n "$desired_comp_min_chf" ]; then
    is_number "$desired_comp_min_chf" || die "--desired_comp_min_chf must be a plain number (got: $desired_comp_min_chf)"
fi
if [ -n "$desired_comp_max_chf" ]; then
    is_number "$desired_comp_max_chf" || die "--desired_comp_max_chf must be a plain number (got: $desired_comp_max_chf)"
fi

# Validate and base64-encode the CV, if one was provided.
resume_b64=""
if [ -n "$resume_pdf" ]; then
    [ -f "$resume_pdf" ] || die "resume file not found: $resume_pdf"
    [ "$(head -c 4 "$resume_pdf")" = "%PDF" ] || die "resume file does not look like a PDF: $resume_pdf"
    pdf_bytes=$(wc -c < "$resume_pdf") || die "could not determine resume file size."
    if [ "$pdf_bytes" -gt "$MAX_PDF_BYTES" ]; then
        die "resume PDF is $pdf_bytes bytes; the limit is $MAX_PDF_BYTES. Compress it or email it to jobs@truewealth.ch instead."
    fi
    resume_b64=$(base64 < "$resume_pdf" | tr -d '\r\n') || die "could not base64-encode the resume."
    if [ "${#resume_b64}" -gt "$MAX_B64_BYTES" ]; then
        die "encoded resume is ${#resume_b64} bytes; the limit is $MAX_B64_BYTES. Compress the PDF or email it to jobs@truewealth.ch instead."
    fi
fi

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

payload="{\"first_name\":\"$(json_escape "$first_name")\""
add_str() { payload="$payload,\"$1\":\"$(json_escape "$2")\""; }
add_raw() { payload="$payload,\"$1\":$2"; }

add_str last_name "$last_name"
add_str full_name "$full_name"
add_str email "$email"
add_str phone "$phone"
add_raw swiss_work_permit "$swiss_work_permit"
if [ -n "$linkedin_url" ]; then add_str linkedin_url "$linkedin_url"; fi
add_str position_code_applying_for "$POSITION_CODE"
add_str address_street "$address_street"
add_str address_city "$address_city"
add_str address_postal_code "$address_postal_code"
add_str address_country "$address_country"
if [ -n "$earliest_availability" ]; then add_str earliest_availability "$earliest_availability"; fi
if [ -n "$desired_comp_min_chf" ]; then add_raw desired_comp_min_chf "$desired_comp_min_chf"; fi
if [ -n "$desired_comp_max_chf" ]; then add_raw desired_comp_max_chf "$desired_comp_max_chf"; fi
add_str application_markdown "$application_markdown"
# Base64 contains no characters that need JSON escaping; append it directly to
# avoid copying a ~1 MB string through json_escape.
if [ -n "$resume_b64" ]; then payload="$payload,\"resume_pdf_base64\":\"$resume_b64\""; fi
add_str source "$SOURCE_OPTION_ID"
payload="$payload}"

resp_file=$(mktemp -t tw_apply_resp.XXXXXX) || die "could not create temp file."
trap 'rm -f "$resp_file"' EXIT

# The payload can approach 1 MB with a CV attached, which is too large to pass
# as an argv entry on some platforms — stream it to curl via stdin instead.
http_code=$(printf '%s' "$payload" | curl -sS -o "$resp_file" -w '%{http_code}' \
    -X POST "$WEBHOOK" \
    -H 'Content-Type: application/json' \
    --data-binary @-) || die "network error while submitting application."

body=$(cat "$resp_file" 2>/dev/null || true)

if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 300 ]; then
    printf 'OK (HTTP %s)\n' "$http_code"
    exit 0
fi

printf 'Submission failed (HTTP %s)\n%s\n' "$http_code" "$body" >&2
exit 1
