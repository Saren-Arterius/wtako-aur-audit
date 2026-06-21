# AUR Audit API

HTTP API for querying AUR package security-audit results.

Base URL: `https://aur-audit.wtako.net`
All responses are JSON. No authentication.

---

## Data model

### `PackageResult`

A single package's latest audit record.

| Field          | Type                                  | Description                                                                 |
| -------------- | ------------------------------------- | --------------------------------------------------------------------------- |
| `guid`         | `string`                              | Internal record id (the AUR RSS guid for the analyzed modification).        |
| `packageName`  | `string \| null`                      | AUR package (base) name. `null` for records written before this was stored. |
| `title`        | `string`                              | RSS item title.                                                             |
| `link`         | `string`                              | AUR package page URL from the feed.                                         |
| `description`  | `string`                              | RSS item description.                                                        |
| `status`       | `"scanned" \| "scanning" \| "error"`  | Analysis state.                                                             |
| `pubDate`      | `string`                              | Raw RSS publication date string.                                            |
| `pubDateTs`    | `number`                              | Publication date as a **unix timestamp in milliseconds**.                   |
| `version`      | `string \| null`                      | Package version that was analyzed (`null` if unknown / not yet scanned).    |
| `analysisOn`   | `number \| null`                      | When analysis completed, **unix timestamp in milliseconds**. `null` while `status` is `scanning`. |
| `aurUrl`       | `string`                              | Canonical `https://aur.archlinux.org/packages/<name>` link.                 |
| `blackFlags`   | `string[]`                            | BLACK findings (confirmed malicious code — LLM-detected malware, exploits, data theft). |
| `redFlags`     | `string[]`                            | RED findings (package scan + folded-in dependency/SSSS findings).           |
| `yellowFlags`  | `string[]`                            | YELLOW findings (package scan + folded-in dependency/SSSS findings).        |

> All timestamps in the API are unix milliseconds (`pubDateTs`, `analysisOn`).
> `pubDate` is the only string-form timestamp, kept alongside its numeric `pubDateTs`.

---

## `GET /packages`

Paginated feed of audit results, newest first.

### Query parameters

| Param    | Type     | Default | Description                                                                          |
| -------- | -------- | ------- | ------------------------------------------------------------------------------------ |
| `filter` | `string` | —       | One of `scanned`, `red`, `yellow`, `black`. `red`/`yellow`/`black` page a dedicated severity index.   |
| `before` | `number` | —       | Opaque cursor: pass the `nextCursor` from a previous page to fetch the next page.    |
| `limit`  | `number` | `100`   | Page size. Must be a positive integer; capped at `500`.                              |

### Response `200`

```json
{
  "packages": [ /* PackageResult, … */ ],
  "nextCursor": 12345
}
```

### Example `PackageResult`

```json
{
  "guid": "abc123...",
  "packageName": "example-package",
  "title": "Example Package 1.0.0",
  "link": "https://aur.archlinux.org/packages/example-package",
  "description": "An example package",
  "status": "scanned",
  "pubDate": "Thu, 01 Jan 2026 00:00:00 GMT",
  "pubDateTs": 1735689600000,
  "version": "1.0.0",
  "analysisOn": 1735689700000,
  "aurUrl": "https://aur.archlinux.org/packages/example-package",
  "blackFlags": [],
  "redFlags": ["Obfuscation detected in PKGBUILD (base64 encoding)"],
  "yellowFlags": ["Network download (curl) detected in PKGBUILD"]
}
```

- `packages` — array of `PackageResult`, ordered most-recent first.
- `nextCursor` — pass as `before` to get the next page, or `null` when the last page has been reached.

### Errors `400`

- `Invalid filter. Allowed: scanned, red, yellow, black`
- `Invalid before parameter: must be a positive number`
- `Invalid limit parameter: must be a positive integer`

### Examples

```bash
# Newest 100 results
curl 'http://localhost:3000/packages'

# Only RED-flagged packages, 50 per page
curl 'http://localhost:3000/packages?filter=red&limit=50'

# Next page using the cursor from the previous response
curl 'http://localhost:3000/packages?filter=red&limit=50&before=12345'
```

---

## `GET /package-analysis`

Fetch the **latest** analysis for one or more specific packages **by name**.
Results are keyed by package name (an object, not an array) so callers can look
them up directly.

### Query parameters

| Param   | Type     | Required | Description                                                              |
| ------- | -------- | -------- | ------------------------------------------------------------------------ |
| `names` | `string` | yes      | Comma-separated AUR package names. Whitespace is trimmed, blanks/dupes dropped. Max **200** names per request. |

Each name resolves to its newest modification via the `aur-package-latest`
index, then to that record's full `PackageResult`.

### Response `200`

```json
{
  "packages": {
    "codex-native-git": { /* PackageResult */ },
    "seanime":          { /* PackageResult */ },
    "never-seen-pkg":   null
  }
}
```

- `packages` — an object mapping **each requested name** to its `PackageResult`,
  or `null` if that package has never been seen/scanned.
- Every requested name appears as a key (including unknown ones, with value `null`).

### Errors `400`

- `Missing required query parameter: names`
- `No package names provided`
- `Too many names (max 200)`

### Examples

```bash
# One package
curl 'http://localhost:3000/package-analysis?names=codex-native-git'

# Several at once
curl 'http://localhost:3000/package-analysis?names=codex-native-git,seanime,python-ten-git'
```

---

## `GET /health`

Liveness probe.

### Response `200`

```json
{ "status": "ok", "timestamp": 1718500000000 }
```

- `timestamp` — server time as a unix timestamp in milliseconds.
