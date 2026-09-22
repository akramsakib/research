# BNPBD admin frontend — deeper static bundle audit

Base: `https://org-admin-x71.bnpbd.org/`

Scope: public JavaScript retrieval and static analysis only; no credentials, writes, fuzzing, or exploit payloads.

JavaScript assets analyzed: **5**

## `https://org-admin-x71.bnpbd.org/main.8a6f75668d88c69c.js`

- Status: `200`
- Size: `593588` bytes
- SHA-256: `072d79b37ab3ba050fcc2f5a888b7fce8e03ed67e9425192323eca3475998b0b`
- API-like paths: `/api/admin/`
- Security/auth strings: `AES`, `X-CSRF-Token`, `adminTokenSecret`, `administrator`, `bypassSecurityTrustHtml`, `innerHTML`, `localStorage`, `sessionStorage`
- Dangerous-string counts: `{"document.write": 0, "eval(": 0, "new Function": 0, "insertAdjacentHTML": 0, "innerHTML": 7, "bypassSecurityTrustHtml": 2}`

## `https://org-admin-x71.bnpbd.org/polyfills.7194fbd22806efaa.js`

- Status: `200`
- Size: `33874` bytes
- SHA-256: `e797a8600f4b87b71c8711143a0d949b7e4ed4cf1f6f8f1f920c800b4ead7b74`
- Dangerous-string counts: `{"document.write": 0, "eval(": 0, "new Function": 0, "insertAdjacentHTML": 0, "innerHTML": 0, "bypassSecurityTrustHtml": 0}`

## `https://org-admin-x71.bnpbd.org/runtime.9d3157fc4cd2b7d6.js`

- Status: `200`
- Size: `4994` bytes
- SHA-256: `42f75ff4a0d0cf4d06f310eeb7581be9f806efd9c7f405705ccf8bb5f8a1c4a3`
- Dangerous-string counts: `{"document.write": 0, "eval(": 0, "new Function": 0, "insertAdjacentHTML": 0, "innerHTML": 0, "bypassSecurityTrustHtml": 0}`

## `https://org-admin-x71.bnpbd.org/scripts.b4bc902bbfe75cc2.js`

- Status: `200`
- Size: `214098` bytes
- SHA-256: `5c673cd5e126cfb45fd8b6d039d5d39c34215ffd7393234bb540f49a05db3bfc`
- Security/auth strings: `innerHTML`
- Dangerous-string counts: `{"document.write": 0, "eval(": 0, "new Function": 0, "insertAdjacentHTML": 0, "innerHTML": 16, "bypassSecurityTrustHtml": 0}`

## `https://org-admin-x71.bnpbd.org/zone.js`

- Status: `ERR`
- Size: `None` bytes
- SHA-256: ``
- Dangerous-string counts: `{}`

## Assessment

- Public bundles expose application metadata, route names, API paths, and client-side auth/storage implementation details.
- Static strings alone do not establish exploitability or authorization bypass.
- Client-side encryption keys must be treated as public because they ship to every browser.
- The separate API audit report records the confirmed preflight CORS misconfiguration.
