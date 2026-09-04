# API reference, United Kingdom

Base URL `https://banking-api.baemingo.se/uk/v1`, or `$BANKING_API_BASE/uk/v1`
if the variable is set. Error codes: `../../references/errors.md`.
Login, poll, cancel, connect, `GET /company` and `GET /events` have the same
shapes as in Sweden; see `../sweden/api.md`. The differences are below.

## POST /login

```json
{ "sandbox": true, "email": "founder@sandbox.baemingo.se" }
```

Response `202` with a `human_step` of type `link`. In sandbox the first poll
returns `complete`. `sandbox: false` returns `not_available` today.

## POST /logins/{id}/companies

Start onboarding a new company. No auth (the complete login is the proof).

```json
{
  "name": "Sandbox Bakery Ltd",
  "registration_number": "12345678",
  "legal_form": "private_limited",
  "address": { "street": "1 Bread Street", "city": "London", "postal_code": "EC4M 9BT" }
}
```

`legal_form`: `private_limited` (default), `public_limited`, `partnership`,
`sole_trader`.

Response `201`:

```json
{
  "company": { "id": "cmp_...", "name": "Sandbox Bakery Ltd", "registration_number": "12345678",
               "status": "onboarding", "application": "app_..." },
  "next_actions": [ { "rel": "connect", "method": "POST", "href": ".../logins/lgn_.../connect", "body": { "company": "cmp_..." } } ]
}
```

## GET /applications/{id}

Auth: key.

```json
{
  "id": "app_...",
  "company": "cmp_...",
  "status": "in_progress",
  "progress": { "completed": 1, "total": 3 },
  "requirements": [
    { "key": "company_details", "kind": "form", "status": "completed", "title": "Company details",
      "description": "...", "schema": { ... }, "prefill": { ... }, "human_step": null, "blocked_by": [], "submit": null },
    { "key": "decision_makers", "kind": "form", "status": "pending", "title": "Directors, signatories and owners",
      "description": "...", "schema": { ... }, "prefill": null, "human_step": null, "blocked_by": [],
      "submit": { "rel": "submit_requirement", "method": "POST", "href": ".../applications/app_.../requirements/decision_makers" } },
    { "key": "bank_account", "kind": "human_step", "status": "blocked", "title": "Bank account at the provider",
      "description": "...", "schema": null, "prefill": null, "human_step": null, "blocked_by": ["decision_makers"], "submit": null }
  ],
  "next_actions": [
    { "rel": "submit_requirement", "method": "POST", "href": ".../requirements/decision_makers" },
    { "rel": "refresh", "method": "GET", "href": ".../applications/app_..." }
  ]
}
```

Statuses: `in_progress`, `awaiting_provider`, `awaiting_human`, `approved`,
`rejected`, `expired`, `cancelled`. When `approved`, the company becomes
`active` and `GET /accounts` starts returning accounts.

## POST /applications/{id}/requirements/{key}

Body per the requirement's `schema`. For `decision_makers`:

```json
{
  "people": [
    { "first_name": "Ada", "last_name": "Lovelace", "date_of_birth": "1985-12-10",
      "email": "ada@example.com", "roles": ["director", "owner"],
      "address": { "street": "2 Analytical Row", "city": "London", "postal_code": "N1 9GU", "country": "GB" } }
  ]
}
```

Roles: `director`, `signatory`, `owner` (25% or more). Returns the refreshed
application. Submitting a `human_step` requirement or a blocked one returns
`invalid_state`.

## Not yet live

Accounts, transactions and payments wait on bank-side permissions. Live
login, members, invitations and webhooks are not built.
