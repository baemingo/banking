#!/usr/bin/env bash
# US sandbox: log in as a fresh persona, create a company, connect for a key,
# submit the decision makers, print the application. Prints the key last.
#
#   scripts/onboard.sh [email]
set -euo pipefail

EMAIL="${1:-founder+$(date +%s)@sandbox.baemingo.se}"
BASE="https://banking-api.baemingo.com/us/v1"
J=(-H 'Content-Type: application/json')

login=$(curl -sS -X POST "$BASE/login" "${J[@]}" -d "{\"sandbox\":true,\"email\":\"$EMAIL\"}")
state=$(curl -sS "$(jq -r '.human_step.poll.href' <<<"$login")")
echo "login: $(jq -r .status <<<"$state"), companies: $(jq -r '.companies|length' <<<"$state")" >&2

create=$(jq -r '.next_actions[] | select(.rel=="create_company") | .href' <<<"$state")
company=$(curl -sS -X POST "$create" "${J[@]}" -d '{
  "name":"Sandbox Bakery LLC","registration_number":"12-3456789","legal_form":"llc",
  "address":{"street":"1 Bread Street","city":"Austin","state":"TX","postal_code":"78701"}}')
echo "company: $(jq -r '.company.id + " " + .company.name + " [" + .company.status + "]"' <<<"$company")" >&2
connect=$(jq -r '.next_actions[] | select(.rel=="connect")' <<<"$company")
key=$(curl -sS -X POST "$(jq -r .href <<<"$connect")" "${J[@]}" -d "$(jq -c .body <<<"$connect")" | jq -r .key)
A=(-H "Authorization: Bearer $key" "${J[@]}")

app=$(curl -sS "$BASE/company" "${A[@]}" | jq -r .application)
curl -sS -X POST "$BASE/applications/$app/requirements/decision_makers" "${A[@]}" -d '{"people":[
  {"first_name":"Ada","last_name":"Lovelace","date_of_birth":"1985-12-10","job_title":"CEO","phone":"+14155550100",
   "roles":["director","signatory","owner","controller"],
   "address":{"street":"2 Analytical Row","city":"Austin","state":"TX","postal_code":"78702","country":"US"}}]}' \
  | jq -c '{status, progress, requirements: [.requirements[] | {key, kind, status}]}' >&2
curl -sS -X POST "$BASE/applications/$app/requirements/business_line" "${A[@]}" -d '{
  "industry_code":"339E","website":"https://sandbox-bakery.example.com",
  "source_of_funds":"Sales of bread and pastries to consumers"}' | jq -c '{status, progress}' >&2
signer=$(curl -sS "$BASE/applications/$app" "${A[@]}" | jq -r '.requirements[] | select(.key=="terms_of_service") | .prefill.signatories[0].id')
curl -sS -X POST "$BASE/applications/$app/requirements/terms_of_service" "${A[@]}" -d "{\"accepted_by\":\"$signer\",\"accepted\":true}" \
  | jq -c '{status, progress, requirements: [.requirements[] | {key, kind, status}]}' >&2

echo "$key"
