# BNPBD API route and behavior audit

Target: `https://api-v2.bnpbd.org`

Scope: low-rate GET/OPTIONS only; no credentials, POST, account creation, data modification, fuzzing, or brute force.

Bundle-derived candidate paths examined: **5**
HTTP observations recorded: **20**

## Candidate paths

- `/api/admin/`
- `/api/admin/logged-in-admin-data`
- `/api/admin/login-bnpbd-admin`
- `/api/admin/signup-bnpbd-admin`
- `/api/csrf-token`

## Interesting observations

- `OPTIONS /api/admin/` from `https://evil.example` → **204**, ACAO=`https://evil.example`, body: ``
- `OPTIONS /api/admin/logged-in-admin-data` from `https://evil.example` → **204**, ACAO=`https://evil.example`, body: ``
- `OPTIONS /api/admin/login-bnpbd-admin` from `https://evil.example` → **204**, ACAO=`https://evil.example`, body: ``
- `OPTIONS /api/admin/signup-bnpbd-admin` from `https://evil.example` → **204**, ACAO=`https://evil.example`, body: ``
- `OPTIONS /api/csrf-token` from `https://evil.example` → **204**, ACAO=`https://evil.example`, body: ``

## Interpretation

- A route name or successful preflight is not proof of authorization bypass.
- Actual data exposure requires an allowed origin and valid authorization; this pass did not use credentials.
- Any suspected issue requires targeted confirmation with a dedicated test account or staging environment.
