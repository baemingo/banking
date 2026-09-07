# Sandbox

You choose sandbox with `"sandbox": true` on `POST /login`. There is no
separate sandbox host.

Personas are emails. Any address works; a new address is a new user with no
companies, which is the normal starting point. The documented default is
`founder@sandbox.baemingo.se`. To get a fresh start, use an address nobody
has used before, for example `founder+<timestamp>@sandbox.baemingo.se`.

Companies you create are real test companies in the test environment. Use
any nine-digit EIN; `12-3456789` is fine. People you add as decision makers
are created as test individuals; use made-up names and dates of birth.
Addresses need a real two-letter state code.

Creating a company also opens a USD account and returns the hosted
verification link. Sandbox accounts start at 0.00 USD and cannot be funded
from the API yet, so payments that need a balance fail for lack of funds.
The response says so plainly. Use routing number `021000021` for a valid
test creditor.
