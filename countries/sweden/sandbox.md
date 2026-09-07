# Sandbox

Sandbox and live are the same API. You choose with `"sandbox": true` on
`POST /login`. Sandbox produces `sk_test_` keys; live produces `sk_live_`
keys after a real BankID approval. No real money moves in sandbox and
nothing you do there reaches a real bank.

## Any personal number works

Log in with any twelve-digit personal number. Make one up for this project
(`YYYYMMDDNNNN`, any digits) and do not copy one from documentation: the
first login creates a private test bank for that number, the same number
always comes back to the same one, and anyone else using the same number
shares it. Nobody using a different number can see it. It holds:

- a person with a name derived from the number;
- one active company with a business account (`Företagskonto`, with a
  Bankgiro number) and a savings account (`Sparkonto`), each with a
  positive balance and about three months of history: customer payments in
  by Bankgiro, supplier payments out, card purchases, Swish, salaries and a
  monthly fee.

Stay with your number; data persists between runs. Numbers nobody has used
for 30 days are cleaned up. These three are published examples and behave
like any other number, but they are shared by everyone who tries them, so
use your own for real work:

| Personal number | Person | Company |
|---|---|---|
| `199511062391` | Victorio Gustafsson | Sunny Days AB |
| `199511072382` | Marie Hassan | Last Straw AB |
| `199511092380` | Johan Johansson | Last Call AB |

In sandbox the BankID human step completes on its own within a couple of
seconds. There is no approve endpoint and nothing to click. Just poll.

## Payments

Payments are signed by the auto-completing BankID and reach `sent`. A
payment dated today is booked at once; a payment dated in the future waits
in the bank's upcoming list until that day. An amount the account cannot
cover fails with reason `insufficientFunds`. The status settles to
`executed`, `scheduled` or `failed` on your next read of accounts or
transactions while the bank session from the approval is alive, so read
once more a minute after approval.

Money paid to another company in the same test bank arrives there: a
`domestic_account` payment to its clearing and account number, or a
`bankgiro` payment to its Bankgiro number, credits that account. That is
how you fund a company you have just onboarded. Payments to anyone else
leave the account and go nowhere, which is what a test bank should do. Use
`5050-1055` as a valid external Bankgiro number and `1234567890128` as a
valid OCR reference.

## Onboarding

Create a company with any ten-digit organisation number of your choosing
(it only has to be unique within your own test bank). The requirements loop is the one the live bank runs: contact
details, credit check, beneficial owners and their questions, know-your-
customer and anti-money-laundering questionnaires, industry codes, a package
choice, then the package's products (Bankgiro, data sharing consent and, for
the Plus package, a debit card holder whose `display_name` must come from
`prefill.allowed_display_names`), signatories, agreement setup, the BankID
signature and finally `finalize`. Submitting `finalize` opens the account:
the company becomes `active` and `GET /accounts` shows a `Företagskonto`
with a zero balance and a Bankgiro number. Fund it from your seeded company
as described above.

`DELETE /applications/{id}` cancels an application. Create the company
again for a fresh one.

## Members

`POST /members` with any twelve-digit personal number adds that person to
the company after the signing Authorization approves. The person exists
only inside your test bank; logging in with their number opens their own
separate test bank and does not show your company.
