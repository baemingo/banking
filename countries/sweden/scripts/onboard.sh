#!/usr/bin/env bash
# Sweden sandbox: log in as a person with no company, create one, connect,
# then drive the onboarding requirements loop with plausible answers until
# only human steps remain. Never finalizes. Prints the key last.
#
#   scripts/onboard.sh [national_id] [org_number]
#
# $BANKING_API_BASE replaces the host (https://banking-api.baemingo.se) when set;
# /se/v1 is always appended. Defaults: Johan Johansson and Last Call AB.
set -euo pipefail

NATIONAL_ID="${1:-199511092380}"
ORG="${2:-5578933433}"
BASE="${BANKING_API_BASE:-https://banking-api.baemingo.se}/se/v1"
J=(-H 'Content-Type: application/json')

login=$(curl -sS -X POST "$BASE/login" "${J[@]}" -d "{\"national_id\":\"$NATIONAL_ID\",\"sandbox\":true}")
poll=$(jq -r '.human_step.poll.href' <<<"$login")
for _ in $(seq 1 20); do
  state=$(curl -sS "$poll")
  [ "$(jq -r .status <<<"$state")" = "complete" ] && break
  sleep 2
done
echo "login: $(jq -r .status <<<"$state"), companies: $(jq -r '.companies|length' <<<"$state")" >&2

create=$(jq -r '.next_actions[] | select(.rel=="create_company") | .href' <<<"$state")
company=$(curl -sS -X POST "$create" "${J[@]}" -d "{\"registration_number\":\"$ORG\"}")
echo "company: $(jq -r '.company.id + " " + .company.name + " [" + .company.status + "]"' <<<"$company")" >&2
connect=$(jq -r '.next_actions[] | select(.rel=="connect")' <<<"$company")
key=$(curl -sS -X POST "$(jq -r .href <<<"$connect")" "${J[@]}" -d "$(jq -c .body <<<"$connect")" | jq -r .key)
A=(-H "Authorization: Bearer $key" "${J[@]}")
app=$(curl -sS "$BASE/company" "${A[@]}" | jq -r .application)

# Questionnaires: answer top-level questions, choosing "Nej" when offered, else the first choice.
answers() {
  jq -c '([.questions[].choices[]?.reveals[]?] | unique) as $revealed
    | [.questions[] | select(.question_id as $q | ($revealed | index($q) | not)) | select((.choices|length) > 0)
      | {question_id, answer_choice_id: ((.choices | map(select(.value | test("^nej$"; "i"))) | .[0]) // .choices[0]).answer_choice_id}]'
}

SKIP="none"
for round in $(seq 1 40); do
  application=$(curl -sS "$BASE/applications/$app" "${A[@]}")
  if [ "$(jq -r '.code // empty' <<<"$application")" = "human_step_required" ]; then
    auth=$(curl -sS -X POST "$BASE/sessions" "${A[@]}")
    p=$(jq -r '.next_actions[0].href' <<<"$auth"); sleep 2; curl -sS "$p" "${A[@]}" >/dev/null
    continue
  fi
  echo "round $round: $(jq -r .status <<<"$application") $(jq -c '[.requirements[] | .key + ":" + .status]' <<<"$application")" >&2
  req=$(jq -c --arg skip "$SKIP" '[.requirements[] | select(.status=="pending" and .kind=="form" and (.key as $k | ($skip | split(",")) | index($k) | not))] | .[0] // empty' <<<"$application")
  if [ -z "$req" ]; then
    if [ "$(jq -r .status <<<"$application")" = "approved" ]; then break; fi
    if jq -e '[.requirements[] | select(.kind=="human_step" and .status=="pending")] | length > 0' <<<"$application" >/dev/null; then
      sleep 3; continue
    fi
    break
  fi
  key_name=$(jq -r .key <<<"$req"); href=$(jq -r .submit.href <<<"$req")
  case "$key_name" in
    applicant_contact|organization_contact) body='{"email":"demo.applicant@baemingo.test","phone":{"country_code":"+46","number":"701234567"}}' ;;
    credit_check) body='{"consent":true}' ;;
    beneficial_owners) body='{"confirm":false}' ;;
    kyc_questions) body=$(jq -c "{answers: $(jq -r .prefill <<<"$req" | answers)}" -n) ;;
    aml_questions) body=$(jq -r .prefill <<<"$req" | jq -c '{products: [.products[] | {product_id, answers: [.questions[] | select((.choices|length)>0) | {question_id, answer_choice_id: .choices[0].answer_choice_id}]}]}') ;;
    beneficial_owner_questions) body=$(jq -r .prefill <<<"$req" | jq -c '{owners: [.owners[] | {national_id, answers: [.questions[] | select((.choices|length) > 0) | {question_id, answer_choice_id: ((.choices | map(select(.value | test("^nej$"; "i"))) | .[0]) // .choices[0]).answer_choice_id}]}]}') ;;
    industry_codes) body=$(jq -r .prefill <<<"$req" | jq -c '{codes: ((.suggested | map(if type=="string" then . else .sniCode end)) | if length>0 then . else ["62010"] end)}') ;;
    package) body=$(jq -r .prefill <<<"$req" | jq -c '{package_id: ((.available | map(.packageId) | map(select(test("BAS"))) | .[0]) // .available[0].packageId)}') ;;
    bankgiro) body='{"configuration":"create_new"}' ;;
    data_sharing_consent) body='{"answer":"yes"}' ;;
    debit_card|credit_card) name=$(jq -r '.prefill.allowed_display_names[0] // "CARD HOLDER"' <<<"$req"); body="{\"national_id\":\"$NATIONAL_ID\",\"display_name\":\"$name\",\"email\":\"demo.applicant@baemingo.test\",\"phone\":{\"country_code\":\"+46\",\"number\":\"701234567\"}}" ;;
    credit_account) body=$(jq -r .prefill <<<"$req" | jq -c '{account_id: .availableAccountIds[0].accountId}') ;;
    credit_products) body=$(jq -r .prefill <<<"$req" | jq -c '{products: [.products[] | {product_id: .productId, credit_limit: 10000}]}') ;;
    signatories) body=$(jq -r .prefill <<<"$req" | jq -c '{national_ids: [.signatories[].nationalId]}') ;;
    agreement_setup) body='{}' ;;
    *) echo "no answer for $key_name; skipping" >&2; SKIP="$SKIP,$key_name"; continue ;;
  esac
  result=$(curl -sS -X POST "$href" "${A[@]}" -d "$body")
  if [ "$(jq -r '.code // empty' <<<"$result")" != "" ]; then
    echo "submit $key_name failed: $(jq -c '{code, detail}' <<<"$result")" >&2
    if [ "$key_name" = "beneficial_owners" ]; then
      curl -sS -X POST "$href" "${A[@]}" -d '{"confirm":true}' >/dev/null
    fi
    SKIP="$SKIP,$key_name"
    continue
  fi
  echo "  submitted $key_name" >&2
done

curl -sS "$BASE/applications/$app" "${A[@]}" | jq -c '{status, progress}' >&2
echo "$key"
