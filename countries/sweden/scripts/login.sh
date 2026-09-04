#!/usr/bin/env bash
# Sweden: log in with a sandbox personal number, wait for BankID to complete,
# connect the first company and print the API key.
#
#   scripts/login.sh [national_id]
#
# $BANKING_API_BASE replaces the host (https://banking-api.baemingo.se) when set;
# /se/v1 is always appended.
# Sandbox by default; set SANDBOX=false for the live bank.
# Defaults to Victorio Gustafsson (Sunny Days AB).
set -euo pipefail

NATIONAL_ID="${1:-199511062391}"
BASE="${BANKING_API_BASE:-https://banking-api.baemingo.se}/se/v1"

login=$(curl -sS -X POST "$BASE/login" -H 'Content-Type: application/json' \
  -d "{\"national_id\":\"$NATIONAL_ID\",\"sandbox\":${SANDBOX:-true}}")
poll=$(jq -r '.human_step.poll.href' <<<"$login")
if [ "$poll" = "null" ]; then
  echo "login failed: $login" >&2
  exit 1
fi
echo "login: $(jq -r .id <<<"$login")" >&2

for _ in $(seq 1 30); do
  state=$(curl -sS "$poll")
  status=$(jq -r .status <<<"$state")
  if [ "$status" = "complete" ]; then
    break
  fi
  if [ "$status" != "pending" ]; then
    echo "login ended: $status" >&2
    exit 1
  fi
  sleep "$(jq -r '(.human_step.poll.after_ms // 2000) / 1000' <<<"$state")"
done

echo "person: $(jq -r .person.name <<<"$state")" >&2
jq -r '.companies[] | "company: \(.id) \(.name) [\(.status)]"' <<<"$state" >&2

connect=$(jq -r '.companies[0].next_actions[] | select(.rel=="connect")' <<<"$state")
key=$(curl -sS -X POST "$(jq -r .href <<<"$connect")" -H 'Content-Type: application/json' \
  -d "$(jq -c .body <<<"$connect")")
echo "key expires: $(jq -r .expires_at <<<"$key")" >&2
jq -r .key <<<"$key"
