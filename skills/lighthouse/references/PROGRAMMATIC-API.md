# Lighthouse programmatic (Node) API

Drive Lighthouse from JavaScript when you need custom flows: bulk runs, authenticated pages, user flows (measuring interactions, not just page load), or feeding results into your own tooling.

> **ESM only.** Lighthouse 10+ ships as an ES module. Use `import` (a `.mjs` file or `"type": "module"` in `package.json`), not `require()`.

## Install

```bash
npm install --save-dev lighthouse chrome-launcher
```

## Basic run

```js
import lighthouse from 'lighthouse';
import * as chromeLauncher from 'chrome-launcher';

const chrome = await chromeLauncher.launch({ chromeFlags: ['--headless=new'] });

const runnerResult = await lighthouse('https://example.com', {
  port: chrome.port,
  output: 'json',
  onlyCategories: ['performance', 'accessibility', 'seo', 'best-practices'],
});

// .lhr = structured result object; .report = formatted (json/html) string
const { lhr } = runnerResult;
console.log('Performance:', Math.round(lhr.categories.performance.score * 100));
console.log('LCP:', lhr.audits['largest-contentful-paint'].displayValue);

await chrome.kill();
```

## Desktop config + throttling

```js
const result = await lighthouse(url, { port: chrome.port }, {
  extends: 'lighthouse:default',
  settings: {
    formFactor: 'desktop',
    screenEmulation: { mobile: false, width: 1350, height: 940, deviceScaleFactor: 1 },
    throttling: { rttMs: 40, throughputKbps: 10240, cpuSlowdownMultiplier: 1 },
  },
});
```

## User flows (measure interactions, including INP)

A single page-load audit can't measure INP. **User flows** capture navigations, timespans (an interaction window), and snapshots.

```js
import { startFlow } from 'lighthouse';
import * as chromeLauncher from 'chrome-launcher';
import puppeteer from 'puppeteer';

const chrome = await chromeLauncher.launch({ chromeFlags: ['--headless=new'] });
const browser = await puppeteer.connect({ browserURL: `http://localhost:${chrome.port}` });
const page = await browser.newPage();

const flow = await startFlow(page, { name: 'Search flow' });

await flow.navigate('https://example.com');           // cold navigation

await flow.startTimespan({ name: 'Type and submit' }); // measure an interaction window
await page.type('#search', 'lighthouse');
await page.click('#submit');
await page.waitForSelector('.results');
await flow.endTimespan();

await flow.snapshot({ name: 'Results state' });        // audit current DOM state

const report = await flow.generateReport();            // combined HTML report
await browser.disconnect();
await chrome.kill();
```

## Bulk runs

```js
const urls = ['https://example.com', 'https://example.com/pricing'];
const chrome = await chromeLauncher.launch({ chromeFlags: ['--headless=new'] });

const results = [];
for (const url of urls) {
  const { lhr } = await lighthouse(url, { port: chrome.port, output: 'json' });
  results.push({
    url,
    performance: Math.round(lhr.categories.performance.score * 100),
    lcp: lhr.audits['largest-contentful-paint'].numericValue,
  });
}

await chrome.kill();
console.table(results);
```

> Reuse **one** Chrome instance across sequential runs (kill it once at the end). Run URLs sequentially unless you launch a separate Chrome per worker — sharing one port across parallel runs corrupts results.

## Authenticated pages

Launch with Puppeteer, log in, then hand the page/port to Lighthouse — or set extra headers / cookies via `extraHeaders` in the Puppeteer page before running the flow above.

## See also

- [Lighthouse user-flows docs](https://github.com/GoogleChrome/lighthouse/blob/main/docs/user-flows.md)
- [Using Lighthouse programmatically](https://github.com/GoogleChrome/lighthouse/blob/main/docs/readme.md#using-programmatically)
