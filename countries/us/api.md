# API reference, United States

Base URL `https://banking-api.baemingo.com/us/v1`. Error codes:
`../../references/errors.md`.
Login, poll, cancel, connect, applications, requirements, `GET /company`,
events, webhooks, cards, loans and members have the same shapes as in the
United Kingdom; see `../uk/api.md`. The differences are below.

## POST /logins/{id}/companies

```json
{
  "name": "Sandbox Bakery LLC",
  "registration_number": "12-3456789",
  "legal_form": "llc",
  "address": { "street": "1 Bread Street", "city": "Austin", "state": "TX", "postal_code": "78701" }
}
```

`registration_number` is the EIN, nine digits with an optional hyphen.
`legal_form`: `llc` (default), `corporation`, `partnership`,
`sole_proprietorship`, `nonprofit`. `address.state` is the two-letter code.

## POST /applications/{id}/requirements/decision_makers

```json
{
  "people": [
    { "first_name": "Ada", "last_name": "Lovelace", "date_of_birth": "1985-12-10",
      "job_title": "CEO", "phone": "+14155550100",
      "roles": ["director", "signatory", "owner", "controller"],
      "address": { "street": "2 Analytical Row", "city": "Austin", "state": "TX", "postal_code": "78702", "country": "US" } }
  ]
}
```

At least one `signatory` and one `controller` are required. The
`business_line` and `terms_of_service` bodies are the same as in the United
Kingdom (`../uk/api.md`); the terms PDFs come from
`GET /applications/{id}/terms/{type}`.

## POST /accounts

Auth: key with the full role.

```json
{ "name": "Tax reserve" }
```

Optional `currency` (defaults to `USD`). Response `201` with the same shape
as an item in `GET /accounts`, balance `0.00`. Emits `account.created`.

## POST /payments

```json
{
  "type": "us_bank_transfer",
  "from_account": "acct_...",
  "amount": { "amount": "125.00", "currency": "USD" },
  "creditor": { "routing_number": "021000021", "account_number": "000123456",
                "account_type": "checking", "name": "Ada Lovelace", "priority": "regular" },
  "message": "Invoice 7"
}
```

`priority`: `regular` (ACH, default), `wire` (Fedwire), `instant` (RTP).
`account_type`: `checking` (default) or `savings`. A routing number that
fails the ABA checksum is refused at `POST /payments/validate` with
`creditor.routing_number: invalid_checksum`. `internal_transfer` takes
`creditor: { "account": "acct_..." }`. `execute_on` must be omitted.

`POST /payments/submit` returns an Authorization that is `approved` at once,
or `rejected` with a `reason`. Sandbox accounts start at 0.00 USD, so a
transfer from an unfunded account is rejected for lack of funds.
