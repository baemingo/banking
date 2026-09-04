---
name: baemingo-banking
description: Baemingo Banking API. Headless business banking for agents, one country at a time. Use when a user wants to build a bank, open a company bank account, read balances and transactions, or make payments in Sweden, Germany or Italy. This skill only tells you which country skill to install.
---

# Baemingo Banking

A headless, agent-first banking API. One host, `https://banking-api.baemingo.se`,
one design language, one spec per country. You build for one country at a
time, so install that country's skill and use nothing else.

| Country | Install | Base URL |
|---|---|---|
| Sweden | `npx skills add baemingo/banking-sweden` | `https://banking-api.baemingo.se/se/v1` |
| Germany | `npx skills add baemingo/banking-germany` (not yet published) | `https://banking-api.baemingo.se/de/v1` |
| Italy | `npx skills add baemingo/banking-italy` (not yet published) | `https://banking-api.baemingo.se/it/v1` |

Every country follows the same two rules:

1. A 90-day API key returns everything: accounts, balances, transactions,
   payment drafts, events. You never log in to read.
2. A human step is required only to send payments, and in Sweden for a few
   live bank actions. It always arrives as the same `human_step` object, and
   in sandbox it completes on its own.

Ask the user which country they are building for, then install that skill.
