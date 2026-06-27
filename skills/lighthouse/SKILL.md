---
name: lighthouse
description: Run Google Lighthouse to measure and verify web quality — performance, accessibility, SEO, and best practices. Use when asked to "run Lighthouse", "measure performance", "check my Lighthouse score", "audit a URL", "set up performance budgets", or "add Lighthouse to CI".
license: MIT
metadata:
  author: nimajafari
  version: "0.1"
---

# Lighthouse

Run [Google Lighthouse](https://github.com/GoogleChrome/lighthouse) to **measure** web quality and **verify** that fixes actually moved the numbers. Lighthouse audits a URL across Performance, Accessibility, SEO, and Best Practices and returns a 0–100 score per category plus a list of failing audits with specific guidance.

## When to use this skill

This skill **measures**. Sibling quality skills **fix**. The workflow is a loop:

```
measure (this skill)  →  fix (performance / accessibility / seo / best-practices)  →  re-measure
```

Reach for this skill to: get a baseline score, find the specific failing audits, set a performance budget, gate a build in CI, or prove a change improved (or regressed) a metric. Don't guess at improvements — measure, change one thing, measure again.

## How it works

1. **Pick a target URL** — a deployed URL, or a local dev/preview server (`http://localhost:3000`).
2. **Run Lighthouse** — prefer `scripts/run-lighthouse.sh <url>`; it runs several times, takes the median, and emits compact JSON (full reports are huge and waste context).
3. **Read category scores + failing audits** from the JSON.
4. **Map each failing audit to a fix** using the relevant quality skill.
5. **Re-run** and report the before/after delta.

## Install & run (CLI)

The Lighthouse readme installs it **globally** (needs Node 22 LTS+), and it drives a
local **Chrome/Chromium** you must have installed:

```bash
npm install -g lighthouse
# or: yarn global add lighthouse

lighthouse https://example.com --view    # basic run; --view opens the HTML report
```

Lighthouse auto-detects an installed Chrome; point it at a specific binary with the
`CHROME_PATH` environment variable.

For a quick one-off without a global install, `npx lighthouse <url>` also works — the
published CLI bin supports it, though the official docs only cover the global install.

**Machine-readable run for an agent** (JSON to a file, quiet, headless):

```bash
npx lighthouse https://example.com \
  --quiet \
  --chrome-flags="--headless=new" \
  --only-categories=performance,accessibility,seo,best-practices \
  --output=json --output-path=./lh.json
```

### The wrapper script (recommended)

`scripts/run-lighthouse.sh` wraps the CLI, runs N times, picks the **median** run (Lighthouse's own guidance for reducing variance), and prints compact JSON to stdout — category scores plus the failing audits only. Human logs go to stderr.

```bash
# Usage: run-lighthouse.sh <url> [runs] [categories]
skills/lighthouse/scripts/run-lighthouse.sh https://example.com 3
skills/lighthouse/scripts/run-lighthouse.sh http://localhost:3000 5 performance,accessibility
```

Example output:

```json
{
  "success": true,
  "url": "https://example.com",
  "runs": 3,
  "lighthouseVersion": "13.x",
  "scores": { "performance": 78, "accessibility": 95, "seo": 92, "best-practices": 96 },
  "failingAudits": [
    { "id": "largest-contentful-paint", "score": 0.4, "displayValue": "4.2 s" },
    { "id": "unused-javascript", "score": 0.3, "displayValue": "Potential savings of 180 KiB" }
  ]
}
```

## Key flags

| Flag | Purpose |
|------|---------|
| `--output=json\|html\|csv` | Report format (repeat for multiple) |
| `--output-path=<path>` | Where to write the report |
| `--only-categories=…` | Limit to `performance,accessibility,seo,best-practices` |
| `--preset=perf\|experimental\|desktop` | Built-in config; `desktop` switches to desktop form-factor + throttling (default is **mobile**: emulated mid-tier phone + slow 4G) |
| `--chrome-flags="--headless=new"` | Run headless (CI/servers); add `--no-sandbox` in containers |
| `--throttling-method=simulate\|devtools\|provided` | How to throttle (`simulate` is default lab throttling; `provided` = no throttling) |
| `--extra-headers '{"Cookie":"…"}'` | Send headers/cookies (auth, feature flags) |
| `--blocked-url-patterns="…"` | Block requests (e.g. measure a page minus third parties) |
| `--save-assets` | Also write the trace + screenshots to disk (debugging) |
| `--quiet` | Suppress progress logging |
| `--view` | Open the HTML report when done |

For every flag (throttling, emulation, `-G`/`-A` gather/audit mode, plugins, etc.), see the complete [references/CLI-FLAGS.md](references/CLI-FLAGS.md) — or run `lighthouse --help`.

## Reading the JSON

Scores are `0–1` floats under `categories`; audit details are under `audits`.

```bash
# Category scores (0–1) → multiply by 100 for the familiar score
jq '.categories | to_entries | map({(.key): (.value.score)}) | add' lh.json

# Core Web Vitals lab values
jq '.audits | {
  LCP: .["largest-contentful-paint"].displayValue,
  CLS: .["cumulative-layout-shift"].displayValue,
  TBT: .["total-blocking-time"].displayValue
}' lh.json

# Failing/opportunity audits worth acting on
jq '[.audits[] | select(.score != null and .score < 0.9)
     | {id, score, displayValue}]' lh.json
```

## Performance budgets

> **Heads up:** the old LightWallet `--budget-path` CLI flag and the
> `performance-budget` / `timing-budget` audits have been **removed** from
> Lighthouse. There is no longer a built-in budget flag on the `lighthouse` CLI.

Enforce budgets in one of two ways instead:

1. **Lighthouse CI assertions (recommended)** — gate a build on metric thresholds
   and category scores with `@lhci/cli`. This is the supported, modern path; see
   [references/CI.md](references/CI.md) for `lighthouserc.js` assertions like:

   ```js
   assertions: {
     'largest-contentful-paint': ['error', { maxNumericValue: 2500 }],
     'cumulative-layout-shift':  ['error', { maxNumericValue: 0.1 }],
     'total-blocking-time':      ['warn',  { maxNumericValue: 300 }],
     'categories:performance':   ['error', { minScore: 0.9 }],
   }
   ```

2. **Assert on the JSON yourself** — for a quick local/CI gate without LHCI, read
   the numeric values out of the report and fail your script:

   ```bash
   lcp=$(jq '.audits["largest-contentful-paint"].numericValue' lh.json)
   awk "BEGIN{exit !($lcp <= 2500)}" || { echo "LCP over budget: ${lcp}ms"; exit 1; }
   ```

## Lab vs. field — read this before trusting a number

Lighthouse is a **lab** tool: one synthetic load, on emulated hardware, with simulated throttling. It is reproducible and great for catching regressions, but it is **not** what real users experience.

- **Variance is real.** A single run can swing ±5–10 points. Run **at least 3 times and take the median** (the wrapper script does this).
- **For real-user data**, use **field** sources instead: [CrUX](https://developer.chrome.com/docs/crux), PageSpeed Insights (which shows both lab + field), Search Console's Core Web Vitals report, or the [`web-vitals`](https://github.com/GoogleChrome/web-vitals) library reporting to your analytics.
- **INP can't be measured in a single Lighthouse load** — it needs real interactions. Lighthouse reports Total Blocking Time (TBT) as its lab proxy; treat field INP as the source of truth.

## Lighthouse v13 note (Insight Audits)

Since v13 (Oct 2025+), Lighthouse [migrated Performance to **Insight Audits**](https://developer.chrome.com/blog/moving-lighthouse-to-insights). Several legacy per-opportunity audit IDs were merged or removed (e.g. CLS-related audits → `cls-culprits-insight`, image audits → `image-delivery-insight`). The *advice* is unchanged; only audit IDs and report grouping moved. When parsing older reports, treat them as a superset, not a contradiction. Pin a Lighthouse version in CI so audit IDs you assert on stay stable.

## How the Performance score is built

The Performance score is a weighted blend of lab metrics (weights shift between versions). As of recent versions, the heavy hitters are roughly:

| Metric | Approx. weight |
|--------|----------------|
| Total Blocking Time (TBT) | ~30% |
| Largest Contentful Paint (LCP) | ~25% |
| Cumulative Layout Shift (CLS) | ~25% |
| First Contentful Paint (FCP) | ~10% |
| Speed Index | ~10% |

Because TBT/LCP/CLS dominate, fixing those moves the score most. Use the [Lighthouse Scoring Calculator](https://googlechrome.github.io/lighthouse/scorecalc/) to see exactly how a metric change maps to points.

## CI and the programmatic API

Kept in references to stay focused:

- **Continuous integration** — `@lhci/cli`, `lighthouserc.js` assertions, and a GitHub Actions workflow: [references/CI.md](references/CI.md)
- **Programmatic (Node) API** — driving Lighthouse with `chrome-launcher` for custom flows, user flows, and bulk runs: [references/PROGRAMMATIC-API.md](references/PROGRAMMATIC-API.md)

## Mapping audits to fixes

| Lighthouse category | Fix with |
|---------------------|----------|
| Performance / Core Web Vitals | a performance or Core Web Vitals skill |
| Accessibility | an accessibility / WCAG skill |
| SEO | an SEO skill |
| Best Practices | a security / best-practices skill |

Pair this skill with [addyosmani/web-quality-skills](https://github.com/addyosmani/web-quality-skills) for the fix side of the loop.

## References

- [Lighthouse repo & Node CLI](https://github.com/GoogleChrome/lighthouse/blob/main/readme.md)
- [Understanding the results](https://github.com/GoogleChrome/lighthouse/blob/main/docs/understanding-results.md)
- [User flows](https://github.com/GoogleChrome/lighthouse/blob/main/docs/user-flows.md)
- [Lighthouse CI (budgets via assertions)](https://github.com/GoogleChrome/lighthouse-ci)
- [Scoring](https://developer.chrome.com/docs/lighthouse/performance/performance-scoring)
- [Full CLI flag reference](references/CLI-FLAGS.md) · [CI setup](references/CI.md) · [Programmatic API](references/PROGRAMMATIC-API.md)
