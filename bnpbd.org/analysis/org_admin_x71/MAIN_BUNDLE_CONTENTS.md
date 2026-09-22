# org-admin-x71 main JavaScript bundle — static contents

Bundle: `https://org-admin-x71.bnpbd.org/main.8a6f75668d88c69c.js`

SHA-256: `072d79b37ab3ba050fcc2f5a888b7fce8e03ed67e9425192323eca3475998b0b`

Size: `593,588 bytes`

## What it is

This is a production Angular/Webpack bundle for the application identified in the code as:

```text
BNPBD.ORG Admin
```

It contains the app's configuration, authentication services, route guards, API service definitions, storage helpers, and Angular framework code.

## Important configuration

```text
API base: https://api-v2.bnpbd.org
FTP/base auxiliary API: https://api.bnpbd.org
Admin API prefix: /api/admin/
Admin login route: /login
Admin post-login route: /dashboard
Version: 2
```

## Admin API routes visible in this file

```text
GET/POST /api/admin/login-bnpbd-admin
POST     /api/admin/signup-bnpbd-admin
GET      /api/admin/logged-in-admin-data
```

The bundle also references the CSRF service endpoint:

```text
/api/csrf-token
```

## Authentication flow

The login service sends credentials to `login-bnpbd-admin`. On a successful response it expects a token and fields such as:

```text
token
tokenExpiredIn
admin ID
role
permissions
pageAccess
```

It then stores an object containing those fields in encrypted `localStorage`, starts a client-side expiry timer, and navigates to `dashboard`.

The API authentication header used elsewhere in the bundle is named:

```text
administrator
```

## Client-side storage and hardcoded key material

The bundle defines storage names similar to:

```text
SOFTLAB_WEB_V2_ADMIN_TOKEN_2
SOFTLAB_WEB_V2_ADMIN_SESSION_2
SOFTLAB_WEB_V2_USER_0_2
```

It also contains constants used as CryptoJS AES passphrases:

```text
SOFT_2021_IT_1998
SOFT_ADMIN_1995_&&_SOJOL_dEv
SOFT_ADMIN_1996_&&_SOBUR_dEv
SOFT_API_1998_&&_SAZIB_dEv
```

These are not server-side secrets because they are shipped to every browser. The encryption protects against casual local inspection only. Anyone who can execute JavaScript in the admin origin can read the bundle and use the same decryption code/key material, or interact with the running app.

## Route guards

The bundle has a client-side guard that redirects unauthenticated users to `/login`, and another that redirects authenticated users away from the login page to `/dashboard`.

These guards are only UX/navigation controls. They are not an authorization boundary. The API must continue to enforce authorization server-side, which prior tests showed with `401 Unauthorized` for a fake admin token.

## Framework/security-related contents

This is a compiled Angular application and includes Angular sanitizer/security code. Static string counts in the main bundle were:

```text
document.write: 0
eval(: 0
new Function: 0
insertAdjacentHTML: 0
bypassSecurityTrustHtml: 2
innerHTML: 7
```

The presence of Angular sanitizer APIs or `innerHTML` strings alone does not prove XSS. No user-controlled source-to-sink path was established in this static review.

## What is not inside it

- No real administrator username/password was found.
- No valid admin session token was found.
- The visible AES constants are not proof of an API compromise.
- The route names do not bypass backend authorization.
- No confirmed XSS was found from this bundle review.

## Security conclusions

1. The bundle exposes useful application metadata and API route names.
2. Client-side AES keys should be treated as public and not relied on for confidentiality.
3. Sensitive admin session state would be safer in a server-controlled session using an `HttpOnly`, `Secure`, appropriately `SameSite` cookie, where compatible with the application.
4. The admin frontend should deploy a strong Content-Security-Policy, especially while sensitive state is accessible to JavaScript.
5. The API must remain the authoritative authorization layer; current fake-token checks returned `401`.
6. If a genuine admin-origin XSS were later found, the localStorage token design would increase impact. XSS has not been confirmed.
