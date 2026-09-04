# Errors

Every error is `application/problem+json`:

```json
{
  "type": "https://banking-api.baemingo.se/errors/key_expired",
  "title": "Key expired",
  "status": 403,
  "code": "key_expired",
  "detail": "This key is past its 90-day lifetime.",
  "remediation": "Log in again and connect the company to get a new key.",
  "retryable": false,
  "request_id": "req_...",
  "next_actions": [{ "rel": "login", "method": "POST", "href": "..." }]
}
```

Always read `remediation`. When `next_actions` is present, it contains the
call that fixes the problem.

| Code | Status | Meaning | What to do |
|---|---|---|---|
| `validation_failed` | 400 | Body or query did not match the schema; `errors[]` lists fields | Fix the listed fields |
| `malformed_json` | 400 | Body was not JSON | Send JSON with `Content-Type: application/json` |
| `unauthenticated` | 401 | No key, unknown key, or key for another country | Log in and connect to get a key |
| `key_expired` | 403 | Key older than 90 days | Follow the `login` action, connect again |
| `key_revoked` | 403 | Key was revoked | Log in and connect again |
| `role_insufficient` | 403 | The member behind the key may not do this | Ask a member with the required role |
| `not_found` | 404 | No such resource visible to this key | Check the id or list the resource |
| `route_not_found` | 404 | Not a route | The feature is not built yet; check the discovery document |
| `human_step_required` | 409 | A person must act first | Start the human step in `next_actions`, wait, retry |
| `invalid_state` | 409 | Resource is in the wrong state for this action | `remediation` says what to do |
| `idempotency_mismatch` | 422 | Same `Idempotency-Key`, different body | Use a new key or resend the identical body |
| `rate_limited` | 429 | Too many requests | Wait `Retry-After` seconds |
| `internal_error` | 500 | Our fault | Retry once, then report `request_id` |
| `provider_unavailable` | 503 | The bank did not answer | Retry with backoff; stored data is unaffected |
