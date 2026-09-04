# Sandbox

You choose sandbox with `"sandbox": true` on `POST /login`. There is no
separate sandbox host.

Personas are emails. Any address works; a new address is a new person with
no companies, which is the normal starting point. The documented default is
`founder@sandbox.baemingo.se`. To get a fresh start, use an address nobody
has used before, for example `founder+<timestamp>@sandbox.baemingo.se`.

Companies you create go to the bank's test environment as real test legal
entities. Use any 8-character Companies House number; `12345678` is fine.
People you add as decision makers are created as test individuals; use made-up
names and dates of birth.

Bank-side steps (account holder, GBP account, verification page) are blocked
until the provider credential has the right roles. The `bank_account`
requirement says so in its description.
