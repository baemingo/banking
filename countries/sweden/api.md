# API reference, Sweden

Error codes: `../../references/errors.md`.

Base URL `https://banking-api.baemingo.se/se/v1`, or `$BANKING_API_BASE/se/v1` if the
variable is set.
All bodies are JSON. All timestamps are ISO 8601 UTC.

## GET /

Discovery. No auth.

```json
{
  "name": "Baemingo Banking API, Sweden",
  "country": "SE",
  "version": "v1",
  "rules": ["..."],
  "links": { "openapi": "...", "llms": "...", "guides": "...", "mcp": "...", "skill": "baemingo/banking-sweden" },
  "next_actions": [{ "rel": "login", "method": "POST", "href": ".../login" }]
}
```

## POST /login

Start a BankID login. No auth.

Request:

```json
{ "national_id": "199511062391", "sandbox": true }
```

`sandbox` defaults to `false`. `true` selects the test bank, where BankID
completes on its own and the key will be `sk_test_`.

Response `202`:

```json
{
  "id": "lgn_...",
  "status": "pending",
  "human_step": {
    "type": "bankid",
    "purpose": "login",
    "url": "bankid:///",
    "qr": null,
    "message": "Open BankID and approve the login.",
    "expires_at": "...",
    "poll": { "href": ".../logins/lgn_...", "after_ms": 2000 }
  },
  "person": null,
  "companies": null,
  "expires_at": "...",
  "next_actions": [
    { "rel": "poll", "method": "GET", "href": ".../logins/lgn_..." },
    { "rel": "cancel", "method": "POST", "href": ".../logins/lgn_.../cancel" }
  ]
}
```

In live, show `human_step.url` or `human_step.qr` to the person. In sandbox,
just poll.

## GET /logins/{id}

Poll a login. No auth. While pending, the same shape as above. When complete:

```json
{
  "id": "lgn_...",
  "status": "complete",
  "human_step": null,
  "person": { "name": "Victorio Gustafsson" },
  "companies": [
    {
      "id": "cmp_...",
      "name": "Sunny Days AB",
      "registration_number": "165554562347",
      "status": "active",
      "application": null,
      "next_actions": [
        { "rel": "connect", "method": "POST", "href": ".../logins/lgn_.../connect", "body": { "company": "cmp_..." } }
      ]
    }
  ],
  "expires_at": "...",
  "next_actions": [
    { "rel": "connect", "method": "POST", "href": "...", "body": { "company": "cmp_..." } },
    { "rel": "create_company", "method": "POST", "href": ".../logins/lgn_.../companies" }
  ]
}
```

Terminal statuses other than `complete`: `failed`, `expired`, `cancelled`.
Then `next_actions` contains a fresh `login` action.

A login is valid for 15 minutes. Connect within that window.

## POST /logins/{id}/cancel

Cancel a pending login. No auth. Returns the login with status `cancelled`.

## POST /logins/{id}/connect

Get a 90-day API key for one of the companies the login listed. No auth
(the login itself is the proof).

Request:

```json
{ "company": "cmp_..." }
```

Response `201`:

```json
{
  "key": "sk_test_...",
  "company": "cmp_...",
  "expires_at": "2026-12-03T14:33:21.066Z",
  "next_actions": [
    { "rel": "company", "method": "GET", "href": ".../company" },
    { "rel": "accounts", "method": "GET", "href": ".../accounts" }
  ]
}
```

The key is shown once. You may connect several companies from one login and
get one key per company.

## GET /company

The company behind the key. Auth: `Authorization: Bearer <key>`.

```json
{
  "id": "cmp_...",
  "name": "Sunny Days AB",
  "registration_number": "165554562347",
  "country": "SE",
  "status": "active",
  "application": null,
  "members": 1,
  "accounts": 0,
  "key": { "expires_at": "...", "role": "full" },
  "created_at": "...",
  "next_actions": [{ "rel": "accounts", "method": "GET", "href": ".../accounts" }]
}
```

## GET /accounts

All accounts with current balances. Auth: key. Balances are always current;
never log in to refresh them.

```json
{
  "data": [
    {
      "id": "acct_...",
      "name": "Kontokredit",
      "nickname": null,
      "type": "credit",
      "currency": "SEK",
      "identifiers": { "clearing_number": "9669", "account_number": "6760115", "iban": "SE57...", "bic": "SVEASESS" },
      "balance": {
        "current": { "amount": "17337.00", "currency": "SEK" },
        "reserved": { "amount": "0.00", "currency": "SEK" },
        "credit_limit": { "amount": "10000.00", "currency": "SEK" },
        "available": { "amount": "27337.00", "currency": "SEK" },
        "as_of": "2026-06-14T22:01:38.000Z",
        "computed_at": "2026-09-04T16:02:11.000Z"
      },
      "status": "active",
      "next_actions": [
        { "rel": "transactions", "method": "GET", "href": ".../accounts/acct_.../transactions" },
        { "rel": "pay_from", "method": "POST", "href": ".../payments" }
      ]
    }
  ],
  "next_cursor": null
}
```

`type` is `current`, `savings` or `credit`. `identifiers` may also carry
`bankgiro` as a list. `available` is `current` minus `reserved` plus
`credit_limit`. `as_of` is the booking time of the last movement, so an old
date means a quiet account; `computed_at` is when the number was produced,
which is always now.

## GET /accounts/{id}

One account, same shape as an item above.

## GET /accounts/{id}/transactions

Booked transactions, newest first. Auth: key.
Query: `limit` (1 to 200, default 50), `cursor`, `from` and `to` (dates,
inclusive), `kind`.

```json
{
  "data": [
    {
      "id": "txn_...",
      "account": "acct_...",
      "amount": { "amount": "-890.00", "currency": "SEK" },
      "kind": "domestic_out",
      "reference": "Elräkning maj",
      "counterparty": null,
      "payment": null,
      "value_date": "2026-06-15",
      "booked_at": "2026-06-14T22:01:38.000Z",
      "balance_after": { "amount": "7337.00", "currency": "SEK" }
    }
  ],
  "next_cursor": "..." 
}
```

Amounts are negative for money out. Follow `next_cursor` until it is null.
Kinds: `bankgiro_in`, `bankgiro_out`, `plusgiro_out`, `domestic_in`,
`domestic_out`, `internal`, `swish_in`, `swish_out`, `card`, `fee`, `other`.

## GET /transactions

Every account of the company in one list, newest first. Same query
parameters and item shape as the per-account list.

## GET /transactions/{id}

One transaction, same shape as an item above.

## GET /openapi.json, GET /llms.txt

The machine-readable spec and the agent instructions, both rendered from the
same source as this document.

## POST /payments

Create a payment. Auth: key. Nothing is sent; see submit.

```json
{
  "type": "bankgiro",
  "from_account": "acct_...",
  "amount": { "amount": "15.00", "currency": "SEK" },
  "creditor": { "bankgiro": "5050-1055" },
  "ocr": "1234567890128",
  "execute_on": "2026-09-12",
  "reference": "inv-2026-0917",
  "queue": true
}
```

Types and their `creditor`:

| type | creditor | extra |
|---|---|---|
| `domestic_account` | `{ "clearing_number": "9669", "account_number": "6760115", "name"? }` | `message`? |
| `bankgiro` | `{ "bankgiro": "5050-1055" }` | `ocr` or `message` |
| `plusgiro` | `{ "plusgiro": "4158-2", "name"? }` | `ocr` or `message` |
| `internal_transfer` | `{ "account": "acct_..." }` another account of the company | `message`? |

Common fields: `from_account`, `amount`, `execute_on` (date, omit for as soon
as possible), `reference` (yours), `queue` (default true; false keeps a
draft). Bankgiro, Plusgiro and OCR numbers are checksum-validated; a bad one
is a `validation_failed` with `invalid_checksum` on the field.

Response `201`:

```json
{
  "id": "pay_...",
  "type": "bankgiro",
  "from_account": "acct_...",
  "amount": { "amount": "15.00", "currency": "SEK" },
  "creditor": { "bankgiro": "5050-1055" },
  "message": null,
  "ocr": "1234567890128",
  "execute_on": "2026-09-12",
  "reference": "inv-2026-0917",
  "status": "queued",
  "verification": "verified",
  "authorization": null,
  "failure": null,
  "created_at": "...",
  "next_actions": [
    { "rel": "submit", "method": "POST", "href": ".../payments/submit", "body": { "payments": ["pay_..."] } },
    { "rel": "update", "method": "PATCH", "href": ".../payments/pay_..." },
    { "rel": "cancel", "method": "POST", "href": ".../payments/pay_.../cancel" }
  ]
}
```

Statuses: `draft`, `queued`, `pending_authorization`, `sent`, `scheduled`,
`executed`, `failed`, `cancelled`. Today payments stop at `sent`; execution
and failure reporting come with the bank's event feed.

## POST /payments/validate

Same body as create. Returns `{ "valid": true, "payment": {...}, "errors": [] }`
or `{ "valid": false, "errors": [ { "field", "code", "message" } ] }`. Creates
nothing.

## GET /payments, GET /payments/{id}

List newest first with `?status=&limit=&cursor=`, or fetch one.

## PATCH /payments/{id}

Change `amount`, `creditor`, `message`, `ocr`, `execute_on` or `reference`
on a draft or queued payment. Re-validated. Anything already submitted
returns `invalid_state`.

## POST /payments/{id}/cancel

Cancel a draft, queued or pending payment.

## POST /payments/submit

The only call that moves money. Auth: key.

```json
{ "payments": ["pay_1", "pay_2"] }
```

Response `202`, an Authorization:

```json
{
  "id": "auth_...",
  "status": "pending",
  "phase": "signing",
  "subject": { "type": "payment_batch", "payments": ["pay_1", "pay_2"] },
  "summary": "2 payments, 27.00 SEK in total",
  "lines": [
    { "payment": "pay_1", "text": "12.00 SEK from Kontokredit 9669 6760115 to Sparkonto 9669 2133280" },
    { "payment": "pay_2", "text": "15.00 SEK to Bankgiro 5050-1055, OCR 1234567890128 from Kontokredit 9669 6760115" }
  ],
  "human_step": {
    "type": "bankid", "purpose": "sign", "url": "bankid:///", "qr": null,
    "message": "Open BankID and sign the payments.",
    "expires_at": "...", "poll": { "href": ".../authorizations/auth_...", "after_ms": 2000 }
  },
  "reason": null,
  "expires_at": "...",
  "next_actions": [
    { "rel": "poll", "method": "GET", "href": ".../authorizations/auth_..." },
    { "rel": "cancel", "method": "POST", "href": ".../authorizations/auth_.../cancel" }
  ]
}
```

`phase` is `login` when the bank first needs a BankID login (no recent
session), then `signing`. Show `human_step` to the person each time it
changes. One batch, one currency, up to 50 payments.

## GET /authorizations/{id}

Poll. Pending returns the shape above with the current `human_step`.
`approved` means every payment in the batch is `sent`. `rejected`, `expired`
and `cancelled` carry `reason` and return the payments to `queued`.

## POST /authorizations/{id}/cancel

Cancel a pending authorization.

## Not yet live

International payments, saved counterparties, onboarding, members, events and
webhooks return `route_not_found` today. Their shapes are in the design
documents at `github.com/baemingo/agentic-banking/docs`.
