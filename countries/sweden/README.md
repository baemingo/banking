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
5. After `sent`, a payment becomes `scheduled` (dated in the future),
   `executed` or `failed` (with `failure.reason`). This settles on your next
   read of accounts or transactions while the bank session from the approval
   is alive, so read once more a minute after approval. Events
   `payment.scheduled`, `payment.executed` and `payment.failed` are written.

`scripts/pay.sh` runs the whole thing in sandbox.

## Opening a new company's account (onboarding)

1. Log in as a person with no company. The complete login has a
   `create_company` action; `POST` it with
   `{ "registration_number": "5578933433" }` (10 digits, or 12 with the 16
   prefix). The company appears with status `onboarding` and an
   `application`.
2. Connect it for a key. `GET /company` gives `application`;
   `GET /applications/{id}` returns `requirements[]`.
3. Loop: take the first `pending` requirement of kind `form`, ask the person
   for what its `schema` needs, `POST` to `submit.href`, fetch again. Every
   form has a `prefill` with what the bank already knows and, for
   questionnaires, the questions and choices. Answer questionnaires with
   `question_id` and `answer_choice_id` pairs.
4. Requirements of kind `human_step` are BankID signatures; show
   `human_step` to the person. In sandbox they complete on their own.
5. The bank needs a live session for onboarding calls. If a call returns
   `human_step_required`, follow its `open_session` action, poll the
   Authorization, then retry. In sandbox that completes on its own too.

Requirement keys you will meet: `applicant_contact`, `credit_check`,
`beneficial_owners`, `kyc_questions`, `aml_questions`, `package`,
`debit_card` (pick `display_name` from `prefill.allowed_display_names`),
`bankgiro`, `data_sharing_consent` (answer `yes`), `agreement_setup`,
`agreement_signature`. The set depends on the package chosen.

`DELETE /applications/{id}` cancels a broken or abandoned application at the
bank; log in and create the company again for a fresh one.

`scripts/onboard.sh` drives the whole loop in sandbox with plausible answers.

## Events and webhooks

`GET /events` is the log of everything that happened, oldest first from a
cursor; poll it when you cannot receive webhooks. `POST /webhooks` with
`{ "url": "https://...", "types": ["payment.sent"] }` (empty `types` means
all) subscribes a URL; the response carries `secret` once. Deliveries are
POSTed as `{ id, type, created_at, company, data }` with a header
`Baemingo-Signature: t=<unix seconds>, v1=<hex HMAC-SHA256 of "t.body" with the secret>`.
Any 2xx counts as delivered; failures retry with backoff for about two hours,
then the webhook is paused and a `webhook.paused` event is written.
`POST /webhooks/{id}/test` sends a `webhook.test` event;
`GET /webhooks/{id}/deliveries` shows attempts.

## Members

`GET /members` lists the people the bank has registered for the company
(its delegates) with their bank access level; it refreshes from the bank
while a session is alive. `POST /members` with
`{ "national_id": "<12 digits>", "access_level"?, "accounts"? }` asks the
bank to add a person. The bank requires a BankID signature, so the response
is an Authorization to poll, and the bank may refuse when the caller is not
a legal representative of the company; the refusal comes back as
`provider_rejected` with the bank's message. Changing or removing members
at the bank is not available yet.

## What exists today

| Endpoint | Status |
|---|---|
| Discovery, `openapi.json`, `llms.txt` | live |
| `POST /login`, `GET /logins/{id}`, `cancel`, `connect` | live |
| `GET /company` | live |
| `GET /accounts`, `GET /accounts/{id}`, transactions | live |
| `POST /payments`, list, get, `PATCH`, `cancel`, `validate` | live |
| `POST /payments/submit`, `GET /authorizations/{id}`, `cancel` | live |
| `POST /logins/{id}/companies`, `GET /applications/{id}`, `POST .../requirements/{key}` | live |
| `POST /sessions`, `GET /events`, `GET /members`, `POST /members` | live |
| `POST /webhooks`, list, `PATCH`, `DELETE`, `test`, `deliveries` | live |
| Payment status after `sent`: `scheduled`, `executed`, `failed` | live, settled on the next read while a bank session is alive |
| International payments, saved counterparties | next |
| Changing or removing members at the bank | after that |

Do not invent endpoints that are not listed as live. If a call returns
`route_not_found`, the feature is not there yet; tell the person so.
