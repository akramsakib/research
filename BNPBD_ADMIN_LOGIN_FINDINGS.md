# BNPBD admin/login surface — initial low-impact finding

Scope used: public HTTPS GET requests and passive certificate transparency lookup only. No credential attempts, brute force, fuzzing, or vulnerability exploitation were performed.

## Most likely admin login pages

### 1. Primary organization admin panel

```text
https://org-admin-x71.bnpbd.org/login
```

Evidence from public frontend JavaScript on `org-admin-x71.bnpbd.org`:

- Application name: `BNPBD.ORG Admin`
- Configured admin login route: `login`
- Configured admin base route: `dashboard`
- Admin API base path: `https://api-v2.bnpbd.org/api/admin/`
- Login-related API route referenced by the frontend: `login-bnpbd-admin`
- Authenticated data route referenced by the frontend: `logged-in-admin-data`

### 2. Vote/admin panel

```text
https://admin-vote.bnpbd.org/login
```

Evidence from public frontend JavaScript on `admin-vote.bnpbd.org`:

- Application name: `BNPBD.ORG Admin`
- Configured admin login route: `login`
- Configured admin base route: `dashboard`
- Admin API base path: `https://api-vote.bnpbd.org/api/admin/`
- Login-related API route referenced by the frontend: `login-bnpbd-admin-login`
- Authenticated data route referenced by the frontend: `logged-in-admin-data`

## Other login/admin-related pages observed

### Public/member login

```text
https://www.bnpbd.org/login/
https://bnpbd.org/login/
```

This appears to be the public/member login, not the admin panel. The main site frontend links to `/login` and `/login/primary-member-fee`.

### Vote/member management login-like apps

```text
https://vote-management.bnpbd.org/login
https://election26.bnpbd.org/login
```

These appear to expose login routes but the frontend patterns are closer to user/member/vote management rather than the dedicated admin panel.

## Misconfigured or non-login endpoints

### `admin.bnpbd.org`

```text
https://admin.bnpbd.org/
https://admin.bnpbd.org/login
```

Returned Cloudflare error `526 Invalid SSL certificate`. This host looks relevant from certificate transparency but was not reachable as a valid HTTPS admin UI during the check.

### API hosts

```text
https://api-v2.bnpbd.org/
https://api.bnpbd.org/
```

These returned JSON `404` responses for `/`, `/login`, `/admin`, and `/auth/login`; they are API hosts, not browser login pages.

## CMS/common-path checks

The main site does not appear to expose common WordPress/Joomla admin paths:

```text
https://bnpbd.org/wp-login.php    -> 404
https://bnpbd.org/wp-admin/       -> 404
https://bnpbd.org/admin/          -> 404
https://bnpbd.org/administrator/  -> 404
```

`robots.txt` and `sitemap.xml` were not available on the main host during the check.

## Security notes for the internal team

- Treat the admin login URLs as sensitive operational information.
- Do not test credentials, brute force, or attempt bypass without explicit written scope.
- `admin.bnpbd.org` returning Cloudflare `526` should be fixed or removed from DNS if unused.
- The public admin JavaScript exposes admin route names and local client-side token/storage configuration. Review whether any client-side constants are actual secrets; if so, rotate them and move secret material server-side.
