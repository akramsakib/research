# BNPBD Katana-discovered API follow-up

Scope: 899 low-rate Katana-discovered URLs across 11 hosts; this report records a focused GET-only verification of API-looking paths. No credentials, writes, fuzzing, or brute force.

## GET results

- `https://api-v2.bnpbd.org/api/our-service/get-all-by` → **200**, 3000 bytes, `application/json`, ACAO=`None`, sensitive-term-indicator=`True`; body=`<redacted>`
- `https://api-v2.bnpbd.org/api/payment/ssl-ipn` → **404**, 82 bytes, `application/json`, ACAO=`None`, sensitive-term-indicator=`False`; body=`<redacted>`
- `https://api-v2.bnpbd.org/api/portfolio/get-all-data` → **200**, 3000 bytes, `application/json`, ACAO=`None`, sensitive-term-indicator=`False`; body=`<redacted>`
- `https://api-v2.bnpbd.org/api/seo-page/get-by/all-program` → **200**, 600 bytes, `application/json`, ACAO=`None`, sensitive-term-indicator=`False`; body=`<redacted>`
- `https://api-v2.bnpbd.org/api/seo-page/get-by/our-leaders` → **200**, 502 bytes, `application/json`, ACAO=`None`, sensitive-term-indicator=`False`; body=`<redacted>`
- `https://bnpbd.org/api/user/` → **404**, 1086 bytes, `text/html`, ACAO=`None`, sensitive-term-indicator=`False`; body=`<redacted>`
- `https://test-ui.bnpbd.org/api/user/` → **502**, 166 bytes, `text/html`, ACAO=`None`, sensitive-term-indicator=`False`; body=`<redacted>`
- `https://api-v2.bnpbd.org/api/csrf-token` → **200**, 52 bytes, `application/json`, ACAO=`None`, sensitive-term-indicator=`True`; body=`<redacted>`
- `https://api-v2.bnpbd.org/api/admin/logged-in-admin-data` → **401**, 43 bytes, `application/json`, ACAO=`None`, sensitive-term-indicator=`False`; body=`<redacted>`

## Assessment

- A GET response from a public content endpoint is not automatically a vulnerability; authorization and data sensitivity must be assessed.
- The payment IPN path was not POSTed or supplied any payment data.
- No response body is published in this report.
- Katana output should be reviewed for route inventory and source analysis; authenticated endpoints require a dedicated test account.
