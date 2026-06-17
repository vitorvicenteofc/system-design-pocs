# URL Shortener

Short URL service where users paste a full URL and receive a shortened link on `short.example.com`.

## Problem

Provide URL shortening and redirect resolution with low operational overhead for persistence and caching.

## Architecture summary

### Context

- **User** interacts with **URL Shortener App** over HTTPS to shorten URLs and follow short links.
- Technology and external data services are shown at the Container level.

### Containers (in scope)

| Container | Technology | Role |
|-----------|------------|------|
| Web Application | React (vanilla SPA) | Paste full URL, receive shortened URL |
| Shorten Function | AWS Lambda | 8-char hash (NPM module), persist to MongoDB, return short URL |
| Redirect Function | AWS Lambda | Resolve hash via cache or MongoDB, redirect to full URL |

### External services

| Service | Role |
|---------|------|
| MongoDB Atlas | Persist full URL + hash (hash indexed) |
| ElastiCache | Cache hash → URL lookups (8h TTL) |

## Flows

### Shorten (write)

1. User pastes URL in Web Application.
2. Web Application calls Shorten Function over HTTP.
3. Shorten Function generates 8-char hash, stores full URL + hash in MongoDB Atlas.
4. Short URL returned to client (e.g. `https://short.example.com/dfdf7368`).

### Redirect (read)

1. User requests `https://short.example.com/{hash}`.
2. Redirect Function checks ElastiCache for hash.
3. On miss: lookup in MongoDB Atlas, store result in ElastiCache (8h TTL).
4. `redirect` (HTTP 302) to full URL.

## Assumptions

- Short URL domain: `short.example.com`.
- Web client calls Lambda directly over HTTP (Lambda Function URLs or equivalent).
- MongoDB Atlas and ElastiCache are externally maintained; not part of the in-scope app boundary.

## Tradeoffs

- **Direct HTTP to Lambda:** Simple for PoC; requires CORS on shorten path; consider edge protection at scale.
- **External Atlas + ElastiCache:** No ops burden for DB/cache; dependency on managed service SLAs.
