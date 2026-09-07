# Sandbox

Sandbox and live are the same API. You choose with `"sandbox": true` on
`POST /login`. Sandbox uses the test environment and produces `sk_test_`
keys; live produces `sk_live_` keys after a real BankID approval. The
personal numbers below only work in sandbox; sending one with
`sandbox: false` returns a `validation_failed` error that says so.

In sandbox the BankID human step completes on its own within a few seconds.
There is no approve endpoint and nothing to click. Just poll.

| Personal number | Person | Company | What you get |
|---|---|---|---|
| `199511092380` | Johan Johansson | none yet | The normal starting point: create a company with organisation number `5578933433` (Last Call AB) and run onboarding |
| `199511062391` | Victorio Gustafsson | Sunny Days AB | Active company, two accounts, cards, inbox. Best for reading data and paying |
| `199511072382` | Marie Hassan | Last Straw AB | Active company, two accounts, one card |

Onboarding in sandbox runs the real flow against the test environment, which
has one usable test organisation. Its application is shared: if someone has
already completed it, the API adopts it and you see the finished state
(status `approved`, every requirement complete) rather than an empty form.
The requirements loop itself is the same in live. `DELETE /applications/{id}`
cancels an application; if the test environment refuses, the cancel still
applies on our side so you can move on. The sandbox never runs the final
"open the account" step, so an approved sandbox company has no accounts. Do
not use `199511082399` / On Time AB: its application is corrupt in the test
environment and every read returns an upstream error.

Sandbox data is shared between everyone using these identities. Do not rely
on balances or transaction counts staying the same.

Payments in sandbox go to the test environment and are signed by the
auto-completing BankID. They reach `sent`. The test environment books most
of them within seconds and the store is refreshed right after approval, so
balances and transactions usually move; do not rely on exact timing. Booked
sandbox payments show up with kind `domestic_out` regardless of type. Use
`5050-1055` as a valid Bankgiro number and `1234567890128` as a valid OCR
reference.

Names may carry a `Demo` prefix from the test environment; the API strips
it.
