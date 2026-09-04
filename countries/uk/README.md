# United Kingdom

Base URL: `https://banking-api.baemingo.se/uk/v1`. When `BANKING_API_BASE`
is set it replaces the host part only, so the base becomes
`$BANKING_API_BASE/uk/v1`. Identity is an email account. There is no BankID:
payments are approved by the API key holder, and a human step appears only
for identity verification during onboarding.

Every endpoint with examples is in `api.md`. Error codes are in
`../../references/errors.md`.

## From nothing to an API key

1. `POST /login` with `{ "sandbox": true, "email": "<any email>" }`. The email
   names a sandbox persona; any address works and a new address is a new
   person with no companies. Live login is not open yet.
2. `GET` the poll href once. In sandbox the login is `complete` on the first
   poll. A new persona has an empty `companies` list and a `create_company`
   action in `next_actions`.
3. `POST` the create_company action with the company name, Companies House
   number, legal form and registered address. The company is created at the
   bank with status `onboarding` and now appears in the list.
4. `POST` its connect action. Response is `201` with `key` (`sk_test_`) and
   `expires_at`, 90 days out. Store the key; it is shown once.
5. Send `Authorization: Bearer <key>` on every call from now on.

`scripts/onboard.sh` does all of it and submits the first requirement.

## Onboarding: the requirements loop

`GET /company` gives `application`. `GET /applications/{id}` returns
`requirements[]`, each with `kind`, `status`, a JSON `schema` for forms and
a `submit` action. Loop: take the first `pending` requirement of kind `form`,
ask the person for what its schema needs, `POST` the body to `submit.href`,
fetch again. Requirements of kind `human_step` carry a link for the person.

Requirements today:

| key | kind | what |
|---|---|---|
| `company_details` | form | completed at creation; resubmit to correct |
| `decision_makers` | form | directors, signatories and owners of 25% or more, each with name, date of birth, address |
| `bank_account` | form (completed by the API) | the bank opens the account holder and a GBP account |
| `bank_capabilities` | human step | what the bank allows, capability by capability, with verification state |
| `verification` | human step | identity and document checks on the bank's hosted page (`human_step.url`) |

## Events and webhooks

Same as Sweden: `GET /events` to poll, `POST /webhooks` to subscribe an
https URL to event types, signed deliveries with `Baemingo-Signature`,
`POST /webhooks/{id}/test` and `GET /webhooks/{id}/deliveries`. See
`../sweden/README.md` for the signature scheme.

## Cards and financing

`GET /cards` lists cards on the company's accounts; `POST /cards`
`{ "account": "acct_...", "holder_name": "ADA LOVELACE", "form": "virtual" }`
issues one (needs the full role and a card product configured at the bank);
`POST /cards/{id}/freeze` and `/unfreeze` toggle it. `GET /loans/offers`
lists financing offers, `POST /loans/offers/{id}/accept` takes one, and
`GET /loans` shows repayment state. Where the bank has not enabled a product
for this platform, the call returns `provider_rejected` with the bank's own
message rather than pretending.

The application's `bank_capabilities` requirement lists every capability the
bank grants the company (settlements, own-account transfers, payouts, cards,
financing, third-party payments) with `allowed` and its verification state,
and names anything the bank has not configured for the platform.

## Members

`GET /members` lists everyone with access and their role: `read_only`,
`limited` (transfers between own accounts, queue external payments for a
full member to send), `full` (everything, including inviting). A `full`
member invites with `POST /members` `{ "email": "...", "role": "limited" }`;
the invitation is accepted the moment a person logs in with that email, and
the company then appears in their list. `PATCH /members/{id}` changes a
role, `DELETE /members/{id}` removes access, `GET /invitations` and
`DELETE /invitations/{id}` manage pending invitations. In sandbox, log in
with the invited email as a persona to accept.

## What exists today

| Endpoint | Status |
|---|---|
| Discovery, `openapi.json`, `llms.txt` | live |
| `POST /login` (sandbox), `GET /logins/{id}`, `cancel`, `connect` | live |
| `POST /logins/{id}/companies` | live |
| `GET /company`, `GET /applications/{id}`, `POST .../requirements/{key}` | live |
| `GET /events` | live |
| `GET /accounts`, `GET /accounts/{id}/transactions`, `GET /transactions` | live |
| `POST /payments`, `validate`, list, `PATCH`, `cancel`, `submit` | live; external transfers are `rejected` until the bank enables `sendToThirdParty` on the platform, and sandbox accounts start at 0.00 GBP |
| `GET /cards`, `POST /cards`, freeze, unfreeze | live where the bank has a card product configured |
| `GET /loans/offers`, accept, `GET /loans` | live once the bank enables Capital on the platform; until then `provider_rejected` |
| `GET /members`, `POST /members`, `PATCH`, `DELETE`, `GET /invitations` | live |
| `POST /webhooks` and the rest of the webhook routes | live |
| Live login | next |

Do not invent endpoints that are not listed as live. If a call returns
`route_not_found`, the feature is not there yet; tell the person so.
