# Sweden

Base URL: `https://banking-api.baemingo.se/se/v1`. When `BANKING_API_BASE`
is set it replaces the host part only, so the base becomes
`$BANKING_API_BASE/se/v1`. Identity is BankID. Payments are Bankgiro, Plusgiro, domestic
account transfers and transfers between the company's own accounts.

Read `sandbox.md` in this folder before making any call. Every endpoint with
examples is in `api.md`. Error codes are in `../../references/errors.md`.

## From nothing to an API key

1. `POST /login` with `{ "national_id": "<12 digits>", "sandbox": true }`.
   Sandbox uses the test bank, a personal number from `sandbox.md`, and
   BankID that completes on its own. Omit `sandbox` or pass `false` for the
   live bank with a real person. Response is `202` with a `human_step`
   (type `bankid`) and `human_step.poll.href`.
2. `GET` the poll href every `poll.after_ms` milliseconds until `status` is
   `complete`. In live, show `human_step.qr` as an image or `human_step.url`
   as a link and let the person approve in their BankID app.
3. The complete login lists `companies`, each with a `connect` action in
   `next_actions` carrying the exact `method`, `href` and `body`. Companies
   with status `onboarding` can be connected too.
4. `POST` that connect action. Response is `201` with `key` (`sk_test_` in
   sandbox, `sk_live_` in live) and `expires_at`, 90 days out. Store the key;
   it is shown once.
5. Send `Authorization: Bearer <key>` on every call from now on.

`scripts/login.sh` does steps 1 to 4 and prints the key.

## Reading data

`GET /company`, `GET /accounts`, `GET /accounts/{id}/transactions`. Balances
are always current; never log in to refresh them. `as_of` is when the last
movement we know of was booked, not when the number was computed.

## Sending money

1. `POST /payments` creates a payment. Types: `domestic_account`, `bankgiro`,
   `plusgiro`, `internal_transfer`. Validated locally (checksums, dates,
   account ownership) and stored as `queued`. Nothing is sent.
2. `POST /payments/submit` with `{ "payments": ["pay_...", ...] }` returns
   `202` with an Authorization. Its `summary` and `lines` are what the person
   approves. Its `human_step` is the BankID prompt.
3. Poll `human_step.poll.href`. In sandbox it approves on its own within a
   few seconds. When `status` is `approved`, the payments are `sent`.
4. `rejected`, `expired` and `cancelled` return the payments to `queued` and
   carry a `reason`.

`scripts/pay.sh` runs the whole thing in sandbox.

## What exists today

| Endpoint | Status |
|---|---|
| Discovery, `openapi.json`, `llms.txt` | live |
| `POST /login`, `GET /logins/{id}`, `cancel`, `connect` | live |
| `GET /company` | live |
| `GET /accounts`, `GET /accounts/{id}`, transactions | live |
| `POST /payments`, list, get, `PATCH`, `cancel`, `validate` | live |
| `POST /payments/submit`, `GET /authorizations/{id}`, `cancel` | live |
| Payment status after `sent` (executed, failed) | next |
| International payments, saved counterparties | next |
| Creating a company (onboarding), members, events, webhooks | after that |

Do not invent endpoints that are not listed as live. If a call returns
`route_not_found`, the feature is not there yet; tell the person so.
