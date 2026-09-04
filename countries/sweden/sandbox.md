# Sandbox

Sandbox and live are the same API. You choose with `"sandbox": true` on
`POST /login`. Sandbox uses the test bank and produces `sk_test_` keys; live
produces `sk_live_` keys after a real BankID approval. The personal numbers
below only work in sandbox; sending one with `sandbox: false` returns a
`validation_failed` error that says so.

In sandbox the BankID human step completes on its own within a few seconds.
There is no approve endpoint and nothing to click. Just poll.

| Personal number | Person | Company | What you get |
|---|---|---|---|
| `199511062391` | Victorio Gustafsson | Sunny Days AB | Active company, two accounts, cards, inbox. Best default. |
| `199511072382` | Marie Hassan | Last Straw AB | Active company, two accounts, one card |
| `199511082399` | Johan Johansson | On Time AB | Onboarding under review at the bank |
| `199511092380` | Johan Johansson | Last Call AB | Onboarding not started; use to try creating a company |

Sandbox data is shared between everyone using these identities. Do not rely
on balances or transaction counts staying the same.

Payments in sandbox go to the bank's test environment and are signed by the
auto-completing BankID. They reach `sent`. The test bank books most of them
within seconds and the store is refreshed right after approval, so balances
and transactions usually move; do not rely on exact timing. Booked sandbox
payments show up with kind `domestic_out` regardless of type. Use
`5050-1055` as a valid Bankgiro number and `1234567890128` as a valid OCR
reference.

Names may carry a `Demo` prefix from the bank's test environment; the API
strips it.
