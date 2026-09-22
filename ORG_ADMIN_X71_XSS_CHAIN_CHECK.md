# org-admin-x71.bnpbd.org — XSS chain check

Date: 2026-09-22

Target:

```text
https://org-admin-x71.bnpbd.org/login
```

Goal: check whether the earlier note — "client-side token storage is low/informational by itself but potentially high if combined with XSS" — can be validated with a safe XSS check.

Scope/method: low-impact reflected/DOM XSS checks on unauthenticated login/admin SPA routes and static review of public JavaScript. No credential capture, stored payloads, brute force, persistence, phishing, or authenticated actions were performed.

---

## Result

No XSS was confirmed in this check.

The risk remains a **conditional impact chain**:

```text
If an attacker finds XSS on the admin origin,
then the admin token stored in browser localStorage is likely exposed/usable,
because the frontend stores admin session data client-side and ships the encryption key in public JavaScript.
```

I did not prove the first condition, XSS.

---

## Reflected XSS checks

I sent benign canary payloads to common unauthenticated locations:

```text
/login?xss=<canary payload>
/login?message=<canary payload>
/login?error=<canary payload>
/login?returnUrl=<canary payload>
/login?redirect=<canary payload>
/login?next=<canary payload>
/login/<canary payload>
/ <canary payload path>
```

Marker used:

```text
ARENA_REFLECT_20260922
```

Result:

```text
No raw payload reflection in the server-rendered HTML response.
No reflected XSS confirmed.
```

The server consistently returned the Angular SPA HTML without reflecting the query/path payload.

---

## Browser/DOM XSS check

I attempted a headless Chromium check with a harmless canary payload that would only set a DOM attribute/title if executed:

```text
data-xss-canary="ARENA_XSS_CANARY_20260922"
```

Tested examples:

```text
/login?xss=<img onerror=...>
/login?message=<svg onload=...>
/login?error=<img onerror=...>
/login?returnUrl=javascript:...
/login?redirect=javascript:...
/login?next=javascript:...
/login#<img onerror=...>
/#/login?xss=<img onerror=...>
/login/<img onerror=...>
```

Result:

```text
No canary execution observed.
```

Important limitation: headless Chromium was served a Cloudflare "Just a moment..." challenge page instead of the real SPA, so this dynamic DOM test is **not conclusive** for the real browser app.

---

## Static JavaScript review

Bundle reviewed:

```text
https://org-admin-x71.bnpbd.org/main.8a6f75668d88c69c.js
SHA-256: 072d79b37ab3ba050fcc2f5a888b7fce8e03ed67e9425192323eca3475998b0b
```

### Dangerous sink scan

No obvious direct app use found for:

```text
document.write
eval(
new Function
insertAdjacentHTML
```

Observed `innerHTML` and `bypassSecurityTrustHtml` usage appears to come from Angular sanitization / third-party spinner UI code, not from a clearly user-controlled admin-login input.

The app includes a snackbar component for showing success/warn/error messages. The visible template appears to render data as Angular text interpolation, which is normally escaped.

### Token/session impact evidence

The public JavaScript shows:

- Admin token is read from local client storage after login.
- Admin API requests include a custom header:

```text
administrator: <admin token>
```

- Unsafe requests include:

```text
X-CSRF-Token: <csrf token>
withCredentials: true
```

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

- The data is AES-encrypted client-side using key-like constants embedded in the public JavaScript bundle.

Security interpretation:

```text
This client-side encryption is obfuscation, not a strong security boundary.
If JavaScript executes on the admin origin, the attacker can likely access/use the same frontend runtime and token material.
```

---

## Current conclusion

Severity status after this check:

```text
XSS: Not confirmed
Token-storage issue: Low/Informational by itself
Combined impact if future/admin-origin XSS exists: High
```

So the previous statement remains accurate, but the exploitable XSS prerequisite was **not proven**.

---

## What would be needed for deeper validation

To safely validate the combined impact further, use one of these controlled options:

1. A staging environment with the same frontend/backend.
2. A dedicated non-privileged admin test account.
3. Written permission to test specific authenticated input fields for stored/reflected XSS.
4. A normal browser session that can pass Cloudflare, with no real admin credentials exposed to the test payload.

Do **not** test stored XSS payloads in production admin fields without explicit written scope and a rollback plan.

---

## Recommended mitigations now

Even without confirmed XSS, reduce the potential impact:

1. Add a strict Content-Security-Policy to the admin frontend.
2. Treat frontend encryption keys as public; do not rely on them for real secrecy.
3. Prefer HTTP-only, Secure, SameSite cookies or another server-controlled session model where feasible.
4. Use short-lived admin access tokens and server-side invalidation.
5. Invalidate admin sessions on logout, password change, role change, and suspicious activity.
6. Keep CSRF protections enabled for state-changing endpoints.
7. Audit all admin inputs that render rich text, file names, profile data, notifications, CMS content, and error messages.
