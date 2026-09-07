---
name: baemingo-banking
description: Headless business banking for agents. The Baemingo Banking API puts a full business bank account behind one HTTP API powered by global, licensed banks and the Baemingo infrastructure platform. This is a completely headless bank, and the user can build whatever front end suits them: a dashboard, a bookkeeping view, a payout tool or a mobile app - built in an afternoon. Everything starts in a sandbox with test companies; nothing real is opened or moved until the user chooses to go live. Funds sit with regulated partner banks, named per country. Use when the user wants to build a bank or fintech product, give a company a business bank account, run treasury, bookkeeping or payouts from code, or pay invoices and suppliers. Covers Sweden, the United Kingdom, the United States, Germany and Italy.
---

# Baemingo Banking

A business bank account behind one HTTP API at
`https://banking-api.baemingo.com`. When the user asks, you can take their
company through account opening, read balances and transactions, and send
payments. Funds are held
by a regulated partner bank; each country's folder names it. There is no
banking app to fit into; build the front end the user actually wants on top
of these calls. Start in the sandbox with test companies; the same calls
work live. Whenever a step needs a person, it arrives as a `human_step`
object with a poll link. Day-to-day calls run on a 90-day API key that you
keep in your own configuration.

## The rules

1. **A 90-day key returns everything.** Accounts, balances, transactions,
   payment drafts. Never log in to read data.
2. **Anything that needs a person arrives as `human_step`.** Login,
   identity checks and signatures during onboarding, and payment approval
   where the country requires it. Show it to the user and poll; in sandbox
   it completes on its own.
3. **Start in the sandbox.** Pass `"sandbox": true` on login. Switch to live
   only when the user asks.
4. **Never show an API key to the user.** Store it in your configuration
   with owner-only permissions.
5. **Follow `next_actions`.** Every response lists what you can do next with
   method, href and body. Do not guess routes. Errors carry `remediation`;
   do what it says. See `references/errors.md`.

## First: which country?

Each country has its own API path, its own login method and its own payment
types. Ask the user which country their company is registered in if you do
not already know, then read that country's folder and follow only that.

| Country | Read | Availability |
|---|---|---|
| Sweden | `countries/sweden/README.md` | live and sandbox |
| United Kingdom | `countries/uk/README.md` | sandbox |
| United States | `countries/us/README.md` | sandbox |
| Germany | `countries/germany/README.md` | not yet available |
| Italy | `countries/italy/README.md` | not yet available |

Each README ends with a "What exists today" table; trust it over any
assumption. Do not mix countries: a key is issued for one country's path and
does not work on another.

## Shared conventions

- Money is `{ "amount": "123.45", "currency": "<ISO 4217>" }`. Decimal strings.
- Lists paginate with `limit` and `cursor`; follow `next_cursor` until null.
- Send `Idempotency-Key: <unique string>` on every POST you might retry.
- Pending resources carry `poll.href` and `poll.after_ms`.
- Machine-readable specs: `GET https://banking-api.baemingo.com/{cc}/v1/openapi.json` and
  `GET https://banking-api.baemingo.com/{cc}/v1/llms.txt`. `GET https://banking-api.baemingo.com/llms.txt` is this document in
  short form.
