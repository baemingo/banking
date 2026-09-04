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

Creating a company also opens the account holder and a GBP account at the
bank's test environment and returns the hosted verification link. Sandbox
accounts start at 0.00 GBP and cannot be funded from the API yet, so
transfers between own accounts fail for lack of funds and external payments
are rejected until the bank enables third-party payouts on the platform.
Both are reported truthfully in the response.
