# org-admin-x71.bnpbd.org login — initial low-impact test

Date: 2026-09-22

Target tested:

```text
https://org-admin-x71.bnpbd.org/login
```

Method: low-impact public HTTPS requests from Kali over Tailscale. No credential attempts, brute force, bypass attempts, exploit payloads, or high-volume fuzzing were performed.

## Executive summary

The admin login page is live and appears to be an Angular single-page application backed by:

```text
https://api-v2.bnpbd.org/api/admin/
```

The unauthenticated admin data endpoint returned `401 Unauthorized`, which is good. The CSRF endpoint returns a CSRF token and an `_csrf` cookie with `HttpOnly`, `Secure`, and `SameSite=Strict`, also good.

Initial hardening issues to review:

1. The frontend does not send a `Content-Security-Policy` header.
2. The public JavaScript bundle exposes admin API route names and key-like client-side constants. If any of those values are treated as real secrets, they must be rotated and moved server-side.
3. API CORS preflight responses for admin endpoints reflected an arbitrary Origin with `Access-Control-Allow-Credentials: true`; actual GET responses did not allow the arbitrary Origin, so this was not confirmed exploitable, but the preflight behavior should be corrected.
4. The public frontend references an admin registration endpoint name: `signup-bnpbd-admin`. Confirm this route is disabled or strongly protected in production.

## Confirmed routes and behavior

### Frontend routes

| Request | Result |
|---|---:|
| `GET https://org-admin-x71.bnpbd.org/` | `200` |
| `GET https://org-admin-x71.bnpbd.org/login` | `200` |
| `GET https://org-admin-x71.bnpbd.org/dashboard` | `200` SPA fallback |
| `GET https://org-admin-x71.bnpbd.org/admin` | `200` SPA fallback |
| `GET https://org-admin-x71.bnpbd.org/assets/` | `403` |

The `/dashboard` and `/admin` paths returning the SPA is normal for a client-side router. Server-side authorization must be enforced by the API, not by the Angular route guard alone.

### Backend/API checks

| Request | Result |
|---|---:|
| `GET https://api-v2.bnpbd.org/api/csrf-token` | `200`, returns CSRF token |
| `GET https://api-v2.bnpbd.org/api/admin/logged-in-admin-data` without token | `401 Unauthorized` |

CSRF cookie observed:

```text
_csrf=<value>; Path=/; HttpOnly; Secure; SameSite=Strict
```

This is a good baseline configuration.

## Response header observations

### Frontend `https://org-admin-x71.bnpbd.org/login`

Present:

```text
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
X-Frame-Options: SAMEORIGIN
X-Content-Type-Options: nosniff
Referrer-Policy: no-referrer-when-downgrade
Permissions-Policy: geolocation=(), microphone=(), camera=()
```

Not observed on the frontend response:

```text
Content-Security-Policy
```

Recommendation: add a production CSP. Start in `Content-Security-Policy-Report-Only`, then enforce once false positives are resolved.

### API `https://api-v2.bnpbd.org/api/csrf-token`

Present:

```text
Content-Security-Policy: default-src 'self'; ...
X-Frame-Options: SAMEORIGIN
X-Content-Type-Options: nosniff
Referrer-Policy: no-referrer
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Resource-Policy: same-origin
Access-Control-Allow-Credentials: true
```

## Public JavaScript indicators

The public app bundle confirms this is the admin SPA. Relevant non-secret indicators:

```text
Application name: BNPBD.ORG Admin
API base: https://api-v2.bnpbd.org
Admin API base path: /api/admin/
Admin login route: login
Admin dashboard/base route: dashboard
Login API route name: login-bnpbd-admin
Logged-in data route name: logged-in-admin-data
Admin registration route name: signup-bnpbd-admin
```

The bundle also contains key-like client-side constants related to admin/user/API token storage. Since browser-delivered JavaScript is public, these must not be treated as secrets. If they protect sensitive data, rotate them and redesign the mechanism so secrets remain server-side.

## CORS observation

Preflight request sent:

```text
OPTIONS https://api-v2.bnpbd.org/api/admin/login-bnpbd-admin
Origin: https://evil.example
Access-Control-Request-Method: POST
Access-Control-Request-Headers: content-type,x-csrf-token,authorization
```

Observed response:

```text
204
Access-Control-Allow-Origin: https://evil.example
Access-Control-Allow-Credentials: true
Access-Control-Allow-Methods: GET, POST, OPTIONS, PUT, DELETE
Access-Control-Allow-Headers: Authorization,Content-Type,X-CSRF-Token,administrator
```

Follow-up `GET` requests with `Origin: https://evil.example` did **not** include `Access-Control-Allow-Origin`, while the approved origin did. Therefore this is currently a hardening finding / needs validation, not a proven data-exfiltration issue.

Recommendation: make preflight behavior match the same strict allowlist used by actual responses. Do not reflect arbitrary origins when `Access-Control-Allow-Credentials: true` is enabled.

## Source map check

Requesting:

```text
https://org-admin-x71.bnpbd.org/main.8a6f75668d88c69c.js.map
```

returned the SPA HTML fallback, not a valid source map JSON file. No source map exposure was confirmed in this initial check.

## Recommended next safe tests

1. Confirm with the team whether admin registration should exist in production.
2. Review CORS middleware configuration for all `/api/admin/*` routes.
3. Add or tune frontend CSP.
4. Validate that every privileged `/api/admin/*` endpoint returns `401/403` without a valid admin token.
5. Confirm login has rate limiting, lockout/slowdown, MFA for admins, and alerting for failed login bursts. Do this only with an approved test account and written rate limits.
6. Review token storage strategy. Prefer short-lived tokens, secure refresh flow, and server-side invalidation on logout/password change.
