# United States

Base URL: `https://banking-api.baemingo.com/us/v1`. Identity is an email
account. Payments are approved by the API key holder, and a human step
appears only for identity verification during onboarding. Funds are held by
Adyen.

Read `sandbox.md` in this folder before making any call. Every endpoint with
examples is in `api.md`. Error codes are in `../../references/errors.md`.

## Opening a company's account

Most users start here: they have no company on the platform yet.

1. `POST /login` with `{ "sandbox": true, "email": "<any email>" }`. The email
   names a sandbox persona; any address works and a new address is a new
   user with no companies. Live login is not open yet.
2. `GET` the poll href once. In sandbox the login is `complete` on the first
   poll. A new user has an empty `companies` list and a `create_company`
   action in `next_actions`. A returning user sees the companies they have
   access to, each with a `connect` action.
3. `POST` the create_company action with the legal business name, EIN, legal
   form and registered address including the two-letter state. The company
   is created with status `onboarding`, a USD account already open, and now
   appears in the list.
4. `POST` its connect action. Response is `201` with `key` (`sk_test_`) and
   `expires_at`, 90 days out. Store the key; it is shown once.
5. Send `Authorization: Bearer <key>` on every call from now on.

`scripts/onboard.sh` does all of it and submits the first requirement.

## Onboarding: the requirements loop

`GET /company` gives `application`. `GET /applications/{id}` returns
`requirements[]`, each with `kind`, `status`, a JSON `schema` for forms and
a `submit` action. Loop: take the first `pending` requirement of kind `form`,
ask the user for what its schema needs, `POST` the body to `submit.href`,
fetch again. Requirements of kind `human_step` carry a link for the user.

| key | kind | what |
|---|---|---|
| `company_details` | form | completed at creation; resubmit to correct |
| `decision_makers` | form | directors, signatories, owners of 25% or more and controllers, each with name, date of birth, job title, phone, address with state. At least one `signatory` and one `controller`; one person may hold every role. Never ask for a social security number or documents: those are collected on the hosted verification page |
| `business_line` | form | industry code, website and where the money comes from |
| `terms_of_service` | form | a signatory reads the PDFs linked in `prefill.documents` and accepts with `{ "accepted_by": "<signatory id>", "accepted": true }` |
| `bank_account` | form (completed by the API) | the USD account, opened at creation |
| `bank_capabilities` | human step | what the company can do, capability by capability, with verification state |
| `verification` | human step | identity and document checks on the hosted verification page (`human_step.url`); `prefill.findings` lists what is still needed |

Ask the user for their line of business and pick the industry code from the
list in the schema; `339E` is a valid test value. Unknown codes come back as
`provider_rejected` naming the field.

## Accounts

`GET /accounts` lists every account with its current balance. `POST /accounts`
`{ "name": "Tax reserve" }` opens another USD account (needs the full role);
move money into it with an `internal_transfer` payment.

## Payments

Types are `us_bank_transfer` and `internal_transfer`. A bank transfer names
`creditor: { "routing_number", "account_number", "account_type", "name", "priority" }`
where `priority` is `regular` (ACH, default), `wire` (Fedwire) or `instant`
(RTP). Routing numbers are checked against the ABA checksum before anything
is sent. Submit returns an Authorization already `approved` with
`human_step: null`; the key holder is the approver. Sandbox accounts start
at 0.00 USD; see `sandbox.md`.

## Events, webhooks, cards, financing, members

Identical to the United Kingdom; read `../uk/README.md` sections "Events and
webhooks", "Cards and financing" and "Members". Only the path differs.

## What exists today

| Endpoint | Status |
|---|---|
| Discovery, `openapi.json`, `llms.txt` | live |
| `POST /login` (sandbox), `GET /logins/{id}`, `cancel`, `connect` | live |
| `POST /logins/{id}/companies` | live |
| `GET /company`, `GET /applications/{id}`, `POST .../requirements/{key}` | live |
| `GET /accounts`, `POST /accounts`, transactions | live |
| `POST /payments`, `validate`, list, `PATCH`, `cancel`, `submit` | live; sandbox accounts start at 0.00 USD |
| `GET /cards`, `POST /cards`, freeze, unfreeze | live |
| `GET /loans/offers`, accept, `GET /loans` | live |
| `GET /members`, `POST /members`, `PATCH`, `DELETE`, `GET /invitations` | live |
| `POST /webhooks` and the rest of the webhook routes | live |
| `GET /events` | live |
| Live login | next |

Do not invent endpoints that are not listed as live. If a call returns
`route_not_found`, the feature is not there yet; tell the user so.
