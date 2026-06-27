# Lighthouse in CI

Gate builds on Lighthouse scores and budgets with [Lighthouse CI (`@lhci/cli`)](https://github.com/GoogleChrome/lighthouse-ci). It runs Lighthouse N times, asserts on the median, and uploads reports.

## Install

```bash
npm install --save-dev @lhci/cli
```

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

Reuse the same `budget.json` (LightWallet format) from the skill:

```js
collect: {
  url: ['http://localhost:3000/'],
  settings: { budgetPath: './budget.json' },
}
```

## GitHub Actions

```yaml
name: Lighthouse CI
on: [pull_request]

jobs:
  lighthouse:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
      - run: npm ci
      - run: npm run build --if-present
      - name: Run Lighthouse CI
        run: |
          npm install -g @lhci/cli
          lhci autorun
        env:
          LHCI_GITHUB_APP_TOKEN: ${{ secrets.LHCI_GITHUB_APP_TOKEN }}
```

Alternative: the maintained [`treosh/lighthouse-ci-action`](https://github.com/treosh/lighthouse-ci-action) wraps the same flow with less boilerplate and posts results to the PR.

## Tips

- **Pin a Lighthouse version** (it's a transitive dep of `@lhci/cli`) so audit IDs and weights don't shift mid-stream and break assertions.
- **Test a built/production bundle**, not the dev server — dev builds are unminified and unrepresentative.
- **Start `warn`, graduate to `error`.** Begin with warnings to learn your real variance, then tighten the ones that matter to `error`.
- **Assert on metrics, not just category scores**, for stable regression gates — `largest-contentful-paint`'s `maxNumericValue` is far less noisy than the rolled-up `categories:performance` score.
