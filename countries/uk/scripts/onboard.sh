#!/usr/bin/env bash
# UK sandbox: log in as a fresh persona, create a company, connect for a key,
# submit the decision makers, print the application. Prints the key last.
#
#   scripts/onboard.sh [email]
#
# $BANKING_API_BASE replaces the host (https://banking-api.baemingo.se) when set;
# /uk/v1 is always appended.
set -euo pipefail

EMAIL="${1:-founder+$(date +%s)@sandbox.baemingo.se}"
BASE="${BANKING_API_BASE:-https://banking-api.baemingo.se}/uk/v1"
J=(-H 'Content-Type: application/json')

login=$(curl -sS -X POST "$BASE/login" "${J[@]}" -d "{\"sandbox\":true,\"email\":\"$EMAIL\"}")
state=$(curl -sS "$(jq -r '.human_step.poll.href' <<<"$login")")
echo "login: $(jq -r .status <<<"$state"), companies: $(jq -r '.companies|length' <<<"$state")" >&2

create=$(jq -r '.next_actions[] | select(.rel=="create_company") | .href' <<<"$state")
company=$(curl -sS -X POST "$create" "${J[@]}" -d '{
  "name":"Sandbox Bakery Ltd","registration_number":"12345678","legal_form":"private_limited",
  "address":{"street":"1 Bread Street","city":"London","postal_code":"EC4M 9BT"}}')
echo "company: $(jq -r '.company.id + " " + .company.name + " [" + .company.status + "]"' <<<"$company")" >&2
connect=$(jq -r '.next_actions[] | select(.rel=="connect")' <<<"$company")
key=$(curl -sS -X POST "$(jq -r .href <<<"$connect")" "${J[@]}" -d "$(jq -c .body <<<"$connect")" | jq -r .key)
A=(-H "Authorization: Bearer $key" "${J[@]}")

app=$(curl -sS "$BASE/company" "${A[@]}" | jq -r .application)
curl -sS -X POST "$BASE/applications/$app/requirements/decision_makers" "${A[@]}" -d '{"people":[
  {"first_name":"Ada","last_name":"Lovelace","date_of_birth":"1985-12-10","roles":["director","owner"],
   "address":{"street":"2 Analytical Row","city":"London","postal_code":"N1 9GU","country":"GB"}}]}' \
  | jq -c '{status, progress, requirements: [.requirements[] | {key, kind, status}]}' >&2

echo "$key"
