# Lighthouse CLI — full flag reference

Every flag from `lighthouse --help`, grouped as the CLI groups them. This is a
snapshot; flags shift between versions, so run `lighthouse --help` (and
`lighthouse --list-all-audits`) for the definitive list on your installed version.

```
lighthouse <url> <options>
```

## Logging

| Flag | Type / default | Description |
|------|----------------|-------------|
| `--verbose` | boolean (false) | Verbose logging |
| `--quiet` | boolean (false) | No progress, debug logs, or errors |

## Configuration

| Flag | Type / default | Description |
|------|----------------|-------------|
| `--save-assets` | boolean (false) | Save the trace + DevTools logs (and screenshots) to disk |
| `--list-all-audits` | boolean | Print all available audit IDs and exit |
| `--list-trace-categories` | boolean | Print required trace categories and exit |
| `--additional-trace-categories` | string | Extra trace categories to capture (comma-delimited) |
| `--config-path` | string | Path to a config JSON (custom audits/categories). Overrides `--preset` |
| `--preset` | `perf` \| `experimental` \| `desktop` | Built-in config. Ignored if `--config-path` is set |
| `--chrome-flags` | string ("") | Space-delimited flags passed to Chrome (e.g. `"--headless=new --no-sandbox"`). `CHROME_PATH` env var selects the binary |
| `--port` | number (0) | DevTools protocol port; `0` = random |
| `--hostname` | string (localhost) | DevTools protocol hostname |
| `--form-factor` | `mobile` \| `desktop` | How metrics are scored + whether mobile-only audits run. For desktop prefer `--preset=desktop` |
| `--screenEmulation` | object | Screen emulation. `--screenEmulation.disabled`, or set `.mobile .width .height .deviceScaleFactor` individually |
| `--emulatedUserAgent` | string | Override the emulated user-agent (`--no-emulatedUserAgent` to disable) |
| `--max-wait-for-load` | number (ms) | Timeout before the page is considered loaded. Very high values bloat traces |
| `--enable-error-reporting` | boolean | Toggle error reporting (`--no-enable-error-reporting` to disable) |
| `--gather-mode`, `-G` | path? | Collect artifacts from a connected browser and save to disk; quits early unless audit-mode is also set |
| `--audit-mode`, `-A` | path? | Process saved artifacts from disk (default `./latest-run/`) — re-audit offline without re-loading the page |
| `--only-audits` | array | Run only these audit IDs |
| `--only-categories` | array | Run only these categories: `accessibility, best-practices, performance, seo` |
| `--skip-audits` | array | Run everything except these audit IDs |
| `--disable-full-page-screenshot` | boolean | Skip the full-page screenshot (can be large) |

> **`-G` / `-A` workflow:** `lighthouse <url> -G` captures artifacts once; then
> `lighthouse -A` re-runs the *audits* against those saved artifacts. Handy for
> iterating on audit selection or config without re-loading the page each time.

## Output

| Flag | Type / default | Description |
|------|----------------|-------------|
| `--output` | array of `json` \| `html` \| `csv` (default `["html"]`) | Report format(s); repeat for multiple |
| `--output-path` | string | Output file, or `stdout`. JSON defaults to stdout; HTML/CSV default to a file named from URL + date. With multiple outputs the path gets each extension: `reports/my-run` → `reports/my-run.report.html`, `…report.json` |
| `--view` | boolean (false) | Open the HTML report in a browser when done |

## Network, throttling & emulation

| Flag | Type / default | Description |
|------|----------------|-------------|
| `--blocked-url-patterns` | array | Block network requests matching these patterns (e.g. measure a page minus third parties) |
| `--disable-storage-reset` | boolean | Don't clear cache/storage before the run (test warm-cache behavior) |
| `--throttling-method` | `devtools` \| `provided` \| `simulate` | Throttling strategy. `simulate` = Lantern lab throttling (default); `provided` = no throttling |
| `--throttling.rttMs` | number | Simulated network RTT (TCP layer) |
| `--throttling.throughputKbps` | number | Simulated download throughput |
| `--throttling.requestLatencyMs` | number | Emulated network RTT (HTTP layer) |
| `--throttling.downloadThroughputKbps` | number | Emulated download throughput |
| `--throttling.uploadThroughputKbps` | number | Emulated upload throughput |
| `--throttling.cpuSlowdownMultiplier` | number | Simulated + emulated CPU throttling |
| `--extra-headers` | string \| path | HTTP headers/cookies to send: stringified JSON or a path to a `.json` file (auth, feature flags) |
| `--precomputed-lantern-data-path` | string | Read Lantern simulation data from this file (overrides observed RTT/latency) |
| `--lantern-data-output-path` | string | Write Lantern simulation data for reuse with `--precomputed-lantern-data-path` |

## Other options

| Flag | Type / default | Description |
|------|----------------|-------------|
| `--version` | boolean | Print version and exit |
| `--help` | boolean | Print help and exit |
| `--cli-flags-path` | string | JSON file of CLI flags to apply; command-line flags still override it |
| `--locale` | string | Locale/language for the report |
| `--plugins` | array | Run the specified Lighthouse plugins |
| `--channel` | string (cli) | Reporting channel label |
| `--chrome-ignore-default-flags` | boolean (false) | Don't apply Lighthouse's default Chrome flags |

## Examples (from `--help`)

```bash
# Open the HTML report after the run
lighthouse <url> --view

# Custom config (custom audits, report generation, etc.)
lighthouse <url> --config-path=./myconfig.js

# Save trace, screenshots, and a named JSON report
lighthouse <url> --output=json --output-path=./report.json --save-assets

# Disable device emulation and all throttling (measure as-is)
lighthouse <url> --screenEmulation.disabled --throttling-method=provided --no-emulatedUserAgent

# Specific Chrome window size
lighthouse <url> --chrome-flags="--window-size=412,660"

# Headless + quiet
lighthouse <url> --quiet --chrome-flags="--headless"

# Send headers/cookies (inline JSON or a file)
lighthouse <url> --extra-headers "{\"Cookie\":\"monster=blue\", \"x-men\":\"wolverine\"}"
lighthouse <url> --extra-headers=./path/to/file.json

# Limit categories
lighthouse <url> --only-categories=performance,seo
```

See also: [Lighthouse readme / Node CLI](https://github.com/GoogleChrome/lighthouse/blob/main/readme.md).
