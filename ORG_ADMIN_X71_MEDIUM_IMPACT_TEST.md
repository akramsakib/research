# org-admin-x71.bnpbd.org — controlled medium-impact test

Date: 2026-09-22

Target:

```text
https://org-admin-x71.bnpbd.org/login
https://api-v2.bnpbd.org/api/admin/
```

## Scope and safety controls

This was a controlled medium-impact test. I performed a small number of active API requests to validate the CORS/token-storage concerns without trying to compromise accounts.

Performed:

- Valid CSRF retrieval from the API.
- One deliberately invalid admin login attempt using a non-existent `.invalid` email/username and non-real password.
- Empty JSON POST to the admin registration endpoint to verify whether unauthenticated registration is blocked.
- Fake admin-token request to verify token validation behavior.
- Static public JavaScript review.

Not performed:

- No real credentials.
- No brute force.
- No password spraying.
- No account creation.
- No stored XSS payloads.
- No destructive or persistence actions.

---

## 1. Controlled login POST with valid CSRF

Flow:

1. `GET https://api-v2.bnpbd.org/api/csrf-token`
2. Preserve returned `_csrf` cookie.
3. Send exactly one invalid login POST to:

```text
POST https://api-v2.bnpbd.org/api/admin/login-bnpbd-admin
```

Payload used contained only deliberately fake/non-existent values:

```text
username/email: arena-security-test-invalid@example.invalid
password: non-real test string
```

### Results

| Origin | CSRF GET | Invalid login POST | ACAO on POST |
|---|---:|---:|---|
| `https://org-admin-x71.bnpbd.org` | 200 | 403 `Access Denied` | `https://org-admin-x71.bnpbd.org` |
| `https://www.bnpbd.org` | 200 | 403 `Access Denied` | `https://www.bnpbd.org` |
| `https://evil.example` | 200 | 403 `Access Denied` | none |

Observed body for allowed origins:

```json
{"statusCode":403,"message":"Access Denied","error":"Forbidden"}
```

### Interpretation

The login endpoint did not proceed to normal credential validation during this test. It returned `403 Access Denied` even with a valid CSRF token/cookie.

This may indicate an additional access control layer such as country allowlisting, WAF logic, deployment access rules, or extra required request context.

Good: arbitrary origin did not receive `Access-Control-Allow-Origin` on the actual POST response.

---

## 2. Admin registration endpoint check

Endpoint referenced in public JavaScript:

```text
/api/admin/signup-bnpbd-admin
```

Test performed:

```text
POST https://api-v2.bnpbd.org/api/admin/signup-bnpbd-admin
Body: {}
With valid CSRF token/cookie
```

This empty body was intentionally used to avoid creating any account.

### Results

| Origin | Status | ACAO |
|---|---:|---|
| `https://org-admin-x71.bnpbd.org` | 401 `Unauthorized` | `https://org-admin-x71.bnpbd.org` |
| `https://www.bnpbd.org` | 401 `Unauthorized` | `https://www.bnpbd.org` |
| `https://evil.example` | 401 `Unauthorized` | none |

Observed body:

```json
{"statusCode":401,"message":"Unauthorized"}
```

### Interpretation

Good: the admin registration endpoint appears protected from unauthenticated access. The request was rejected with `401 Unauthorized` before any account-creation action.

The public frontend still exposes the route name, but this test indicates the backend requires authorization.

---

## 3. Fake admin token validation

Test performed:

```text
GET https://api-v2.bnpbd.org/api/admin/logged-in-admin-data
administrator: invalid-token-for-security-test
```

### Results

| Origin | Status | ACAO |
|---|---:|---|
| `https://org-admin-x71.bnpbd.org` | 401 `Unauthorized` | `https://org-admin-x71.bnpbd.org` |
| `https://www.bnpbd.org` | 401 `Unauthorized` | `https://www.bnpbd.org` |
| `https://evil.example` | 401 `Unauthorized` | none |

### Interpretation

Good: fake admin tokens are rejected.

Review item: `https://www.bnpbd.org` is still allowed to read responses from some `/api/admin/*` actual responses. This is not exploitable without a valid `administrator` token, but the admin API CORS allowlist should be reduced if the public site does not need admin API access.

---

## 4. CORS status after medium test

The previous finding still stands:

- Actual responses for arbitrary origins do not include `Access-Control-Allow-Origin`.
- But preflight `OPTIONS` responses reflect arbitrary origins with credentials enabled.

Risk remains:

```text
Low/Medium hardening issue, not confirmed exploitable in this test.
```

Recommended fix:

- Do not reflect arbitrary origins on preflight.
- Use the same strict allowlist for OPTIONS and actual responses.
- For admin API routes, allow only origins that genuinely need admin API access.
- Consider limiting admin API CORS to:

```text
https://org-admin-x71.bnpbd.org
```

unless other origins are required.

---

## 5. Public JavaScript/token-storage status after medium test

Bundle checked:

```text
https://org-admin-x71.bnpbd.org/main.8a6f75668d88c69c.js
SHA-256: 072d79b37ab3ba050fcc2f5a888b7fce8e03ed67e9425192323eca3475998b0b
Size: 593,588 bytes
```

Observed in the public bundle:

```text
localStorage usage: present
AES usage: present
custom admin auth header name: administrator
login route: login-bnpbd-admin
signup route: signup-bnpbd-admin
```

Dangerous sink counts from static string scan:

```text
document.write: 0
eval(: 0
new Function: 0
insertAdjacentHTML: 0
bypassSecurityTrustHtml: 2
innerHTML: 7
```

The `innerHTML`/`bypassSecurityTrustHtml` occurrences appear consistent with Angular/third-party UI/sanitizer code rather than a confirmed user-controlled sink from the login page.

### Source map note

The source-map URL returned HTTP 200 in one script, but manual content inspection showed it returns the Angular SPA HTML fallback rather than valid source-map JSON. No valid source map exposure was confirmed.

---

## Updated severity assessment

### Confirmed good controls

- `signup-bnpbd-admin` rejected unauthenticated empty POST with `401 Unauthorized`.
- Fake admin token rejected with `401 Unauthorized`.
- Invalid login attempt with valid CSRF returned `403 Access Denied`.
- Actual CORS responses did not expose data to `https://evil.example`.
- No reflected/DOM XSS was confirmed in prior checks.

### Remaining issues

1. **CORS preflight misconfiguration**
   - Severity: Low/Medium hardening issue.
   - Preflight reflects arbitrary origins with credentials enabled.
   - Not confirmed exploitable because actual responses and auth/CSRF controls blocked access.

2. **Client-side token storage / public encryption keys**
   - Severity: Low/Informational by itself.
   - Potentially High if combined with a real admin-origin XSS.
   - XSS was not confirmed.

3. **Missing frontend CSP**
   - Severity: Medium hardening issue.
   - Important because if XSS is ever introduced, admin localStorage token material could likely be accessed or used.

---

## Recommended next steps

1. Fix CORS preflight to stop reflecting arbitrary origins.
2. Remove `https://www.bnpbd.org` from the admin API CORS allowlist unless explicitly required.
3. Add a strong `Content-Security-Policy` on the admin frontend.
4. Treat all frontend AES/key constants as public; do not rely on them as secrets.
5. Consider server-controlled admin sessions using `HttpOnly`, `Secure`, `SameSite` cookies if feasible.
6. Continue authenticated testing only with a dedicated low-privilege admin test account and written limits.
