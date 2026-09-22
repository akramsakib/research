# BNPBD client-side API data exposure check

Target: `https://api-v2.bnpbd.org`

Scope: unauthenticated low-rate GET requests to API paths exposed by public client bundles. No credentials, POST, mutations, fuzzing, or brute force.

Candidate API paths: **5**
GET requests: **5**

## Results
- `/api/admin/` → **404**, 73 bytes, `application/json`, JSON-like=`True`, record-like=`False`, possible-sensitive-terms=`False`, ACAO=`None`
- `/api/admin/logged-in-admin-data` → **401**, 43 bytes, `application/json`, JSON-like=`True`, record-like=`False`, possible-sensitive-terms=`False`, ACAO=`None`
- `/api/admin/login-bnpbd-admin` → **401**, 43 bytes, `application/json`, JSON-like=`True`, record-like=`False`, possible-sensitive-terms=`False`, ACAO=`None`
- `/api/admin/signup-bnpbd-admin` → **401**, 43 bytes, `application/json`, JSON-like=`True`, record-like=`False`, possible-sensitive-terms=`False`, ACAO=`None`
- `/api/csrf-token` → **200**, 52 bytes, `application/json`, JSON-like=`True`, record-like=`False`, possible-sensitive-terms=`True`, ACAO=`None`

## Potentially interesting 200 responses

- `/api/csrf-token` returned a non-empty 200 response (52 bytes; JSON-like=True; possible-sensitive-terms=True). Response content was not copied into this public report.

## Assessment

- A JSON response or public configuration value is not automatically a vulnerability.
- The report intentionally stores response metadata only and does not publish returned data.
- Admin data endpoints previously tested returned 401 without a valid administrator token.
- A confirmed data-exposure finding requires showing that sensitive records are accessible without authorization, which this pass did not establish unless specifically listed above.
