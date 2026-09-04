---
name: baemingo-banking
description: Build a bank or banking features on the Baemingo Banking API. Headless business banking for agents in Sweden (BankID, Bankgiro, Plusgiro), the United Kingdom (email login, Faster Payments), Germany and Italy (SEPA). Use when a user wants to build their own bank, a finance dashboard, onboard a company, read company accounts, balances and transactions, or make and approve payments. Sandbox first, no secrets in prompts, one country at a time.
---

# Baemingo Banking

Headless business banking for agents. You get a company's accounts,
balances, transactions and payments through one HTTP API at
`https://banking-api.baemingo.se`. A person is needed exactly twice: to log
in and connect a company, and every time money leaves the company. Both
arrive as the same `human_step` object. Everything else runs on a 90-day
API key that you keep in your own configuration.

If the environment variable `BANKING_API_BASE` is set, it replaces the host
`https://banking-api.baemingo.se` (local and staging deployments). Country
paths such as `/se/v1` are appended to it.

## The rules

1. **A 90-day key returns everything.** Accounts, balances, transactions,
   payment drafts. Never log in to read data.
2. **A human step is needed only to send payments**, and in some countries
   for a few live bank actions. It always arrives as `human_step`. In
   sandbox it completes on its own; you just poll.
3. **Start in the sandbox.** Pass `"sandbox": true` on login. Switch to live
   only when the person asks.
4. **Never show an API key to the person.** Store it in your configuration
   with owner-only permissions.
5. **Follow `next_actions`.** Every response lists what you can do next with
   method, href and body. Do not guess routes. Errors carry `remediation`;
   do what it says. See `references/errors.md`.

## First: which country?

Each country has its own API path, its own login method and its own payment
types. Ask the person which country their company is registered in if you do
not already know, then read that country's folder and follow only that.

| Country | Read | Status |
|---|---|---|
| Sweden | `countries/sweden/README.md` | live: login, accounts, transactions, payments |
| United Kingdom | `countries/uk/README.md` | sandbox: login, company creation, onboarding loop. Accounts and payments wait on bank permissions |
| Germany | `countries/germany/README.md` | not yet available |
| Italy | `countries/italy/README.md` | not yet available |

Do not mix countries. A Swedish key does not work on the German path and
vice versa.

## Shared conventions

- Money is `{ "amount": "123.45", "currency": "SEK" }`. Decimal strings.
- Ids are prefixed: `cmp_` company, `lgn_` login, `acct_` account, `txn_`
  transaction, `pay_` payment, `auth_` authorization.
- Lists paginate with `limit` and `cursor`; follow `next_cursor` until null.
- Send `Idempotency-Key: <unique string>` on every POST you might retry.
- Pending resources carry `poll.href` and `poll.after_ms`.
- Machine-readable specs: `GET {base}/{cc}/v1/openapi.json` and
  `GET {base}/{cc}/v1/llms.txt`. `GET {base}/llms.txt` is this document in
  short form.
