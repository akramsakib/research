# BNPBD full Katana crawl and source inventory

Scope: authorized production-safe crawl across the approved BNPBD host list. Katana used GET crawling only with depth 2, concurrency 2, and rate limit 1 request/second. No forms, credentials, writes, fuzzing, or brute force.

- URLs discovered: **899**
- Hosts observed: **11**
- JavaScript assets/URLs observed: **627**
- API-looking URLs observed: **15**

## Hosts observed

- `admin-vote.bnpbd.org`
- `api-v2.bnpbd.org`
- `api-vote.bnpbd.org`
- `api.bnpbd.org`
- `bnpbd.org`
- `election26.bnpbd.org`
- `org-admin-x71.bnpbd.org`
- `photoframe.bnpbd.org`
- `test-ui.bnpbd.org`
- `vote-management.bnpbd.org`
- `www.bnpbd.org`

## API-looking URLs

- `https://admin-vote.bnpbd.org/api/`
- `https://admin-vote.bnpbd.org/api/admin/`
- `https://api-v2.bnpbd.org/api/our-service/get-all-by`
- `https://api-v2.bnpbd.org/api/payment/ssl-ipn`
- `https://api-v2.bnpbd.org/api/portfolio/get-all-data`
- `https://api-v2.bnpbd.org/api/seo-page/get-by/all-program`
- `https://api-v2.bnpbd.org/api/seo-page/get-by/our-leaders`
- `https://bnpbd.org/api/user/`
- `https://org-admin-x71.bnpbd.org/api/`
- `https://org-admin-x71.bnpbd.org/api/admin/`
- `https://test-ui.bnpbd.org/api/`
- `https://test-ui.bnpbd.org/api/user/`
- `https://vote-management.bnpbd.org/api/`
- `https://vote-management.bnpbd.org/api/user/`
- `https://www.bnpbd.org/api/`

## Analysis status

- The crawl inventory is used to drive source and API analysis.
- Public content API schemas are documented separately without publishing response values.
- Payment/IPN-looking routes were not POSTed or supplied payment data.
- Any authenticated route or state-changing behavior requires a dedicated test account and explicit action scope.

## Publication handling

- Raw response bodies are not included in the public report.
- Internal credentials, tokens, and connection metadata are excluded.
