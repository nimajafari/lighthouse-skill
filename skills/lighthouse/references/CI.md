# Lighthouse in CI

Gate builds on Lighthouse scores and budgets with [Lighthouse CI (`@lhci/cli`)](https://github.com/GoogleChrome/lighthouse-ci). It runs Lighthouse N times, asserts on the median, and uploads reports.

## Install

```bash
npm install --save-dev @lhci/cli
```

> **Bundled Lighthouse version:** `@lhci/cli` **0.16.0+** runs **Lighthouse 13.6**
> internally (and needs Node 22.19+), the same major version as `npx lighthouse`. Its
> reports include the v13 Insight audits (`*-insight`), its `lighthouse:recommended`
> presets target them, and assertions that use replaced legacy audit IDs are mapped
> to the IDs that replaced them. **0.15.x and older run Lighthouse 12.x**, with no
> Insight audits. When you upgrade from 0.15.x, re-check every audit-level assertion.
> Metric, category-score, and `resource-summary` assertions carry over unchanged.
> Check `lighthouseVersion` in an LHCI report to confirm which version you're
> asserting against.

## Configure — `lighthouserc.js`

```js
module.exports = {
  ci: {
    collect: {
      // Either point at a running server...
      url: ['http://localhost:3000/', 'http://localhost:3000/pricing'],
      numberOfRuns: 3,
      // ...or let LHCI start your server and wait for it:
      // startServerCommand: 'npm run start',
      // startServerReadyPattern: 'ready on',
    },
    assert: {
      preset: 'lighthouse:recommended',
      assertions: {
        'categories:performance': ['error', { minScore: 0.9 }],
        'categories:accessibility': ['error', { minScore: 1 }],
        'categories:seo': ['warn', { minScore: 0.9 }],
        'categories:best-practices': ['warn', { minScore: 0.95 }],
        // Assert specific metrics directly:
        'largest-contentful-paint': ['error', { maxNumericValue: 2500 }],
        'cumulative-layout-shift': ['error', { maxNumericValue: 0.1 }],
        'total-blocking-time': ['warn', { maxNumericValue: 300 }],
      },
    },
    upload: {
      // Quickest: ephemeral public report link in the logs.
      target: 'temporary-public-storage',
      // Or run your own server: target: 'lhci', serverBaseUrl: '...', token: '...'
    },
  },
};
```

Run locally:

```bash
npx lhci autorun
```

`autorun` = `collect` → `assert` → `upload`. A failed assertion exits non-zero, failing the build.

## Budgets in CI

Lighthouse removed the old LightWallet `budget.json` / `--budget-path` mechanism, so
**budgets in CI are expressed as assertions** (above) rather than a separate budget
file. Use `maxNumericValue` on the metric audits to cap timings/sizes:

```js
assertions: {
  'largest-contentful-paint': ['error', { maxNumericValue: 2500 }],
  'total-blocking-time':      ['error', { maxNumericValue: 300 }],
  'resource-summary:script:size': ['warn', { maxNumericValue: 300000 }],
  'resource-summary:total:size':  ['warn', { maxNumericValue: 1500000 }],
}
```

(`resource-summary:*` byte budgets are in **bytes**; timings in **ms**.)

## GitHub Actions

```yaml
name: Lighthouse CI
on: [pull_request]

jobs:
  lighthouse:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - uses: actions/setup-node@v7
        with:
          node-version: 22
      - run: npm ci
      - run: npm run build --if-present
      - name: Run Lighthouse CI
        run: |
          npm install -g @lhci/cli@0.16.x
          lhci autorun
        env:
          LHCI_GITHUB_APP_TOKEN: ${{ secrets.LHCI_GITHUB_APP_TOKEN }}
```

Alternative: the maintained [`treosh/lighthouse-ci-action`](https://github.com/treosh/lighthouse-ci-action) wraps the same flow with less boilerplate and posts results to the PR.

## Tips

- **Pin `@lhci/cli`** (which pins its bundled Lighthouse: 13.6 as of 0.16.x) so audit IDs and weights don't shift mid-stream and break assertions. When an LHCI release moves to a new Lighthouse version, re-check every audit-level assertion.
- **Test a built/production bundle**, not the dev server — dev builds are unminified and unrepresentative.
- **Start `warn`, graduate to `error`.** Begin with warnings to learn your real variance, then tighten the ones that matter to `error`.
- **Assert on metrics, not just category scores**, for stable regression gates — `largest-contentful-paint`'s `maxNumericValue` is far less noisy than the rolled-up `categories:performance` score.
