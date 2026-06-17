# URL Shortener v2

Hardened URL shortener design with edge governance, API throttling, and reduced redirect latency at scale.

Evolution of [url-shortener](../url-shortener/) with architectural improvements from scalability review.

## Problem

Free public URL shortening with expected load of ~**5M requests/day** (~58 avg RPS, ~175–300 peak RPS), split **30% writes / 70% reads**, without user accounts.

## Load assumptions

| Metric | Value |
|--------|--------|
| Users/day | 1M |
| Requests/user | 5 |
| Total requests/day | 5M |
| Writes (shorten) | 1.5M/day (~17 req/s avg) |
| Reads (redirect) | 3.5M/day (~41 req/s avg) |

## Context

Product-oriented view: **User** and **URL Shortener App** only. Technology choices appear at Container and Deployment levels.

## v2 improvements over v1

| Area | v1 | v2 |
|------|----|----|
| HTTP entry | Lambda Function URLs | CloudFront → API Gateway → Lambda |
| Abuse / cost control | None | API Gateway throttling + AWS WAF |
| Custom domain | Implied | CloudFront for `short.example.com` |
| SPA delivery | Browser-only | S3 + CloudFront |
| Redirect latency | On-demand Lambda | Provisioned concurrency on Redirect Function |
| Cache | ElastiCache 8h TTL | Same, with explicit hit-ratio / sizing goal |

## Containers (in scope)

| Container | Technology | Role |
|-----------|------------|------|
| Web Application Firewall | AWS WAF | Rate limiting and bot protection |
| CloudFront | AWS CloudFront | Front door; SPA + API/redirect routing |
| Static Web Assets | Amazon S3 | Hosts React SPA build |
| Web Application | React (vanilla SPA) | Paste URL; call API to shorten |
| API Gateway | Amazon API Gateway | Routes, throttling, API governance |
| Shorten Function | AWS Lambda | Hash + MongoDB write |
| Redirect Function | AWS Lambda | Cache/Mongo lookup + HTTP 302 |

## External data services

| Service | Role |
|---------|------|
| MongoDB Atlas | Persist full URL + hash (hash indexed) |
| ElastiCache | Cache hash → URL (8h TTL); sized for hot working set |

## Flows

### Shorten (write)

1. User loads SPA via CloudFront (WAF-inspected).
2. User pastes URL; Web Application calls `POST /api/shorten` on API Gateway.
3. API Gateway invokes Shorten Function (throttled).
4. Shorten Function writes hash + URL to MongoDB Atlas; returns short URL.

### Redirect (read)

1. User requests `GET https://short.example.com/{hash}` via CloudFront → API Gateway.
2. API Gateway invokes Redirect Function (provisioned warm instances).
3. Redirect Function checks ElastiCache; on miss, reads MongoDB Atlas and caches result (8h TTL).
4. HTTP 302 redirect to full URL.

## Governance

- **API Gateway:** per-stage throttling on shorten endpoint; protects Lambda and Mongo write path.
- **AWS WAF:** rate-based rules and managed rule sets on CloudFront; mitigates abuse on free public service.

## Cache strategy

- **Goal:** high hit ratio on read path (70% of traffic).
- **Key:** `{hash}` → full URL.
- **TTL:** 8 hours.
- **Monitor:** cache hit rate, Mongo miss rate, redirect p99 latency.

## Cold starts

- **Redirect Function:** provisioned concurrency **25–50** warm instances (starting range; tune with metrics).
- **Shorten Function:** on-demand only (writes lower volume; cold start less critical).

## Assumptions

- Short URL domain: `short.example.com`.
- MongoDB Atlas and ElastiCache are external managed data services (`ContainerDb_Ext`).
- Lambda connection reuse within execution environment to limit Mongo connection churn.

## Tradeoffs

- **More moving parts than v1:** higher setup cost; better governance and redirect latency at scale.
- **Provisioned concurrency:** predictable redirect latency; ongoing cost for warm instances.
- **WAF + API Gateway:** operational overhead; essential for free public shorten endpoints.
