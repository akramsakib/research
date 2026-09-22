# BNPBD ABH follow-up — low-impact API exposure checks

Target: `https://api-v2.bnpbd.org`

Scope: small fixed list of common health/documentation/security paths using GET only. No credentials, writes, fuzzing, brute force, or high-volume scanning.

## Results

- `/` → **404**, 63 bytes, `application/json`, ACAO=`None`, sensitive-term-indicator=`False`; response body preview: `<redacted>`
- `/health` → **404**, 69 bytes, `application/json`, ACAO=`None`, sensitive-term-indicator=`False`; response body preview: `<redacted>`
- `/status` → **404**, 69 bytes, `application/json`, ACAO=`None`, sensitive-term-indicator=`False`; response body preview: `<redacted>`
- `/api` → **404**, 66 bytes, `application/json`, ACAO=`None`, sensitive-term-indicator=`False`; response body preview: `<redacted>`
- `/api/health` → **404**, 73 bytes, `application/json`, ACAO=`None`, sensitive-term-indicator=`False`; response body preview: `<redacted>`
- `/api/status` → **404**, 73 bytes, `application/json`, ACAO=`None`, sensitive-term-indicator=`False`; response body preview: `<redacted>`
- `/api/docs` → **404**, 71 bytes, `application/json`, ACAO=`None`, sensitive-term-indicator=`False`; response body preview: `<redacted>`
- `/api-json` → **404**, 71 bytes, `application/json`, ACAO=`None`, sensitive-term-indicator=`False`; response body preview: `<redacted>`
- `/openapi.json` → **404**, 75 bytes, `application/json`, ACAO=`None`, sensitive-term-indicator=`False`; response body preview: `<redacted>`
- `/swagger` → **404**, 70 bytes, `application/json`, ACAO=`None`, sensitive-term-indicator=`False`; response body preview: `<redacted>`
- `/swagger/` → **404**, 71 bytes, `application/json`, ACAO=`None`, sensitive-term-indicator=`False`; response body preview: `<redacted>`
- `/swagger.json` → **404**, 75 bytes, `application/json`, ACAO=`None`, sensitive-term-indicator=`False`; response body preview: `<redacted>`
- `/docs` → **404**, 67 bytes, `application/json`, ACAO=`None`, sensitive-term-indicator=`False`; response body preview: `<redacted>`
- `/graphql` → **404**, 70 bytes, `application/json`, ACAO=`None`, sensitive-term-indicator=`False`; response body preview: `<redacted>`
- `/api/admin` → **404**, 72 bytes, `application/json`, ACAO=`None`, sensitive-term-indicator=`False`; response body preview: `<redacted>`
- `/api/admin/` → **404**, 73 bytes, `application/json`, ACAO=`None`, sensitive-term-indicator=`False`; response body preview: `<redacted>`
- `/api/admin/logged-in-admin-data` → **401**, 43 bytes, `application/json`, ACAO=`None`, sensitive-term-indicator=`False`; response body preview: `<redacted>`
- `/api/csrf-token` → **200**, 52 bytes, `application/json`, ACAO=`None`, sensitive-term-indicator=`True`; response body preview: `<redacted>`
- `/robots.txt` → **404**, 73 bytes, `application/json`, ACAO=`None`, sensitive-term-indicator=`False`; response body preview: `<redacted>`
- `/.well-known/security.txt` → **404**, 87 bytes, `application/json`, ACAO=`None`, sensitive-term-indicator=`False`; response body preview: `<redacted>`

## Assessment

- No response body was copied in full into this public report.
- Documentation or health endpoints are not automatically vulnerabilities; exposure must be assessed for sensitive content.
- Authenticated authorization testing still requires a dedicated test account.
