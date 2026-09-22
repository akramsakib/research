# org-admin-x71.bnpbd.org — CORS and public JavaScript re-check

Date: 2026-09-22

Target:

```text
https://org-admin-x71.bnpbd.org/login
https://api-v2.bnpbd.org/api/admin/
```

Scope/method: low-impact public HTTP checks and static review of the public JavaScript bundle. I did not use credentials, brute force, fuzz, exploit, or attempt bypass. One malformed empty JSON POST was sent to the login endpoint only to verify CORS/CSRF behavior; no username/password was submitted.

---

## Finding 4 re-check: CORS behavior

### Summary

The API actual responses mostly enforce an Origin allowlist, but preflight responses for admin endpoints reflect arbitrary origins with credentials enabled.

This is **not confirmed as directly exploitable** from the checks performed, because actual responses for arbitrary origins did not include `Access-Control-Allow-Origin`, unauthenticated admin data returned `401`, and state-changing login POST without a CSRF token returned `403 invalid csrf token`.

Still, the preflight behavior should be fixed because it is unnecessarily permissive and can let browsers send cross-origin credentialed unsafe/custom-header requests to admin endpoints.

### Tested origins

```text
https://org-admin-x71.bnpbd.org
https://www.bnpbd.org
https://admin-vote.bnpbd.org
https://evil.example
null
```

### Actual GET: CSRF token endpoint

Endpoint:

```text
GET https://api-v2.bnpbd.org/api/csrf-token
```

Observed behavior:

| Origin | Status | ACAO | ACAC |
|---|---:|---|---|
| `https://org-admin-x71.bnpbd.org` | 200 | `https://org-admin-x71.bnpbd.org` | `true` |
| `https://www.bnpbd.org` | 200 | `https://www.bnpbd.org` | `true` |
| `https://admin-vote.bnpbd.org` | 200 | none | `true` |
| `https://evil.example` | 200 | none | `true` |
| `null` | 200 | none | `true` |

The token body is not browser-readable from arbitrary origins because `Access-Control-Allow-Origin` is absent for those origins.

### Actual GET: unauthenticated admin data

Endpoint:

```text
GET https://api-v2.bnpbd.org/api/admin/logged-in-admin-data
```

Observed behavior:

| Origin | Status | ACAO | ACAC | Body |
|---|---:|---|---|---|
| `https://org-admin-x71.bnpbd.org` | 401 | `https://org-admin-x71.bnpbd.org` | `true` | `Unauthorized` |
| `https://www.bnpbd.org` | 401 | `https://www.bnpbd.org` | `true` | `Unauthorized` |
| `https://admin-vote.bnpbd.org` | 401 | none | `true` | `Unauthorized` |
| `https://evil.example` | 401 | none | `true` | `Unauthorized` |
| `null` | 401 | none | `true` | `Unauthorized` |

Good: unauthenticated access returned `401`.

Review needed: `https://www.bnpbd.org` is allowed to read responses from an `/api/admin/*` endpoint. If not required, remove it from the admin API CORS allowlist.

### Preflight: admin endpoints

Endpoints checked:

```text
OPTIONS /api/admin/login-bnpbd-admin
OPTIONS /api/admin/signup-bnpbd-admin
OPTIONS /api/admin/logged-in-admin-data
```

For all tested origins, including `https://evil.example` and `null`, the API returned:

```text
204
Access-Control-Allow-Origin: <reflected Origin>
Access-Control-Allow-Credentials: true
Access-Control-Allow-Methods: GET, POST, OPTIONS, PUT, DELETE
Access-Control-Allow-Headers: Authorization,Content-Type,X-CSRF-Token,administrator
```

This is the main CORS hardening issue.

### Malformed login POST check

Endpoint:

```text
POST https://api-v2.bnpbd.org/api/admin/login-bnpbd-admin
Body: {}
```

Results:

| Origin | Status | ACAO | Body |
|---|---:|---|---|
| `https://org-admin-x71.bnpbd.org` | 403 | `https://org-admin-x71.bnpbd.org` | `invalid csrf token` |
| `https://www.bnpbd.org` | 403 | `https://www.bnpbd.org` | `invalid csrf token` |
| `https://admin-vote.bnpbd.org` | 403 | none | `invalid csrf token` |
| `https://evil.example` | 403 | none | `invalid csrf token` |
| `null` | 403 | none | `invalid csrf token` |

This suggests the reflected preflight is not enough by itself to read the login response or bypass CSRF.

### Risk assessment

Severity: **Low to Medium hardening issue**, not confirmed exploitable from this limited test.

Why not confirmed exploitable:

- Arbitrary origins did not receive ACAO on actual GET/POST responses.
- Unauthenticated admin data returned `401`.
- Unsafe POST without CSRF token returned `403`.
- The admin frontend appears to send the admin token via a custom `administrator` header; a malicious external origin cannot read the admin origin’s localStorage to obtain that token.

Why it still matters:

- Preflight responses should not reflect arbitrary origins, especially with `Access-Control-Allow-Credentials: true`.
- Browsers may proceed with cross-origin unsafe/custom-header requests after a permissive preflight, even if the response cannot be read.
- Any future endpoint that relies on cookies or misses CSRF/auth checks could become more exposed because preflight already allows arbitrary origins.

### Recommended fix

Use a strict CORS allowlist for both preflight and actual responses. Do not reflect arbitrary origins.

Recommended admin API allowlist:

```text
https://org-admin-x71.bnpbd.org
```

Only add other origins if they genuinely need admin API access.

For disallowed origins:

- Return no `Access-Control-Allow-Origin`, or reject preflight with `403`.
- Do not send `Access-Control-Allow-Credentials: true` without a matching allowed origin.
- Add `Vary: Origin` consistently.

---

## Finding 5 re-check: public JavaScript route/key exposure

### Summary

The public Angular bundle exposes admin route names, API endpoint names, token storage key names, and several key-like client-side constants.

This is **not automatically a remote vulnerability**, because browser JavaScript is always public. However, any value shipped to the browser must be treated as public, not secret.

### Bundle checked

```text
https://org-admin-x71.bnpbd.org/main.8a6f75668d88c69c.js
```

Observed:

```text
Size: 593,588 bytes
SHA-256: 072d79b37ab3ba050fcc2f5a888b7fce8e03ed67e9425192323eca3475998b0b
```

### Source map check

Requesting:

```text
https://org-admin-x71.bnpbd.org/main.8a6f75668d88c69c.js.map
```

returned the SPA HTML fallback, not valid source-map JSON. No valid source map exposure was confirmed.

### Admin indicators in public JS

The public bundle exposes:

```text
Application name: BNPBD.ORG Admin
API base: https://api-v2.bnpbd.org
FTP/upload/API base: https://api.bnpbd.org
Admin API path: /api/admin/
Admin login route: login
Admin base/dashboard route: dashboard
Login API route: login-bnpbd-admin
Logged-in data API route: logged-in-admin-data
Admin registration route: signup-bnpbd-admin
CSRF endpoint: csrf-token
Admin auth header name: administrator
CSRF header name: X-CSRF-Token
```

### Client-side token storage behavior

Static review of the minified bundle shows:

- Admin session data is stored in `localStorage` under an app-specific key.
- The stored object includes fields resembling:

```text
token
expiredDate
adminId
role
permissions
adminPageAccess
```

- It is encrypted with client-side AES using a key-like value embedded in the same public JavaScript bundle.
- The admin token is then added to API requests using the custom header:

```text
administrator: <admin token>
```

- For unsafe methods, the frontend adds:

```text
X-CSRF-Token: <loaded csrf token>
withCredentials: true
```

### Security interpretation

Client-side encryption of localStorage with a key embedded in public JavaScript should be treated as obfuscation, not cryptographic protection.

If an attacker obtains JavaScript execution on the admin origin, they can either:

1. Read/decrypt the token from localStorage because the decryption key is in the public bundle, or
2. Use the app’s own runtime/services to send authenticated requests.

This means the missing frontend CSP from the previous report increases impact: XSS on the admin origin would likely compromise admin sessions.

### Risk assessment

Severity: **Low/Informational by itself**, potentially **High if combined with XSS**.

Publicly exposed route names are not a vulnerability if the backend enforces auth correctly. Exposed client-side constants become a concern if the team believes they are secrets or uses them for meaningful cryptographic protection.

### Recommended fixes

1. Treat all frontend constants as public.
2. Do not rely on client-side encryption keys to protect admin tokens.
3. Prefer short-lived access tokens and server-side refresh/session controls.
4. Invalidate admin tokens on logout, password change, role change, and suspected compromise.
5. Consider moving sensitive session state to secure, HTTP-only, SameSite cookies if compatible with the architecture, with strong CSRF protection.
6. Add a strong CSP to reduce XSS impact.
7. Confirm `signup-bnpbd-admin` is disabled or server-side restricted in production.
8. Do not depend on hidden route names; enforce server-side authentication and authorization on every `/api/admin/*` endpoint.

---

## Bottom line

- **Finding 4:** Preflight CORS is definitely too permissive, but actual responses and CSRF prevented a confirmed exploit in this test.
- **Finding 5:** Public JS contains admin implementation details and key-like constants. Treat these as public information and remove any reliance on them as secrets.
