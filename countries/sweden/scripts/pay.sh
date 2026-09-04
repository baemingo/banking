#!/usr/bin/env bash
# Sweden sandbox: log in, queue an internal transfer and a Bankgiro payment,
# submit both, poll the authorization until approved, print the result.
#
#   scripts/pay.sh
#
# Uses $BANKING_API_BASE if set, otherwise the production base URL.
set -euo pipefail

BASE="${BANKING_API_BASE:-https://banking-api.baemingo.se/se/v1}"
HERE="$(cd "$(dirname "$0")" && pwd)"

KEY=$(BANKING_API_BASE="$BASE" "$HERE/login.sh" 199511062391 2>/dev/null)
AUTH=(-H "Authorization: Bearer $KEY" -H 'Content-Type: application/json')

accounts=$(curl -sS "$BASE/accounts" "${AUTH[@]}")
from=$(jq -r '.data[0].id' <<<"$accounts")
to=$(jq -r '.data[1].id // .data[0].id' <<<"$accounts")

p1=$(curl -sS -X POST "$BASE/payments" "${AUTH[@]}" -H "Idempotency-Key: pay-$(date +%s)-1" -d "{
  \"type\":\"internal_transfer\",\"from_account\":\"$from\",
  \"amount\":{\"amount\":\"12.00\",\"currency\":\"SEK\"},
  \"creditor\":{\"account\":\"$to\"},\"message\":\"Skill test\",\"reference\":\"skill-1\"}")
p2=$(curl -sS -X POST "$BASE/payments" "${AUTH[@]}" -H "Idempotency-Key: pay-$(date +%s)-2" -d "{
  \"type\":\"bankgiro\",\"from_account\":\"$from\",
  \"amount\":{\"amount\":\"15.00\",\"currency\":\"SEK\"},
  \"creditor\":{\"bankgiro\":\"5050-1055\"},\"ocr\":\"1234567890128\",\"reference\":\"skill-2\"}")
id1=$(jq -r .id <<<"$p1"); id2=$(jq -r .id <<<"$p2")
echo "queued $id1 $id2" >&2

auth=$(curl -sS -X POST "$BASE/payments/submit" "${AUTH[@]}" -d "{\"payments\":[\"$id1\",\"$id2\"]}")
echo "authorization: $(jq -r '.id + " " + .summary' <<<"$auth")" >&2
poll=$(jq -r '.next_actions[] | select(.rel=="poll") | .href' <<<"$auth")

for _ in $(seq 1 20); do
  state=$(curl -sS "$poll" "${AUTH[@]}")
  status=$(jq -r .status <<<"$state")
  echo "poll: $status $(jq -r '.phase // ""' <<<"$state")" >&2
  if [ "$status" != "pending" ]; then
    break
  fi
  sleep "$(jq -r '(.human_step.poll.after_ms // 2000) / 1000' <<<"$state")"
done

jq -c '{status, reason, lines: [.lines[].text]}' <<<"$state"
