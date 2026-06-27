# Lighthouse Skill

An [Agent Skill](https://agentskills.io/) for running [Google Lighthouse](https://github.com/GoogleChrome/lighthouse) from your coding agent — to **measure** web quality and **verify** that fixes actually moved the numbers.

Most quality guidance tells an agent *what good looks like*. This skill closes the loop: it teaches the agent to actually run Lighthouse, read the scores, set budgets, gate CI, and re-measure after a change.

```
measure (this skill)  →  fix  →  re-measure
```

**Stack-agnostic.** Works against any deployed URL or local dev server — React, Vue, Svelte, Astro, plain HTML, anything.

## What it covers

- **CLI** — run audits headless, limit categories, desktop vs mobile, JSON output
- **A wrapper script** — `run-lighthouse.sh` runs N times, takes the median, and emits compact JSON (scores + failing audits) instead of a multi-MB report
- **Performance budgets** — LightWallet `budget.json` to fail on regressions
- **CI** — `@lhci/cli`, assertions, and a GitHub Actions workflow ([references/CI.md](skills/lighthouse/references/CI.md))
- **Programmatic API** — driving Lighthouse with `chrome-launcher`, including user flows for INP ([references/PROGRAMMATIC-API.md](skills/lighthouse/references/PROGRAMMATIC-API.md))

## Install

**Manual:**

```bash
cp -r skills/* ~/.claude/skills/
```

**Claude Code (plugin):**

```text
/plugin marketplace add nimajafari/lighthouse-skill
/plugin install lighthouse-skill@nimajafari-lighthouse-skill
```

**Via add-skill:**

```bash
npx add-skill nimajafari/lighthouse-skill
```

## Usage

The skill activates when your request matches its description. Examples:

```
Run Lighthouse on https://example.com and tell me what to fix first
```

```
Set up a performance budget and add Lighthouse CI to this repo
```

```
Measure my homepage, then re-measure after the change to confirm it improved
```

## Requirements

- Node.js 18+ (`npx lighthouse`)
- A Chrome/Chromium install (Lighthouse drives it headless)
- `jq` for the wrapper script's JSON output

## Related

Pair with [addyosmani/web-quality-skills](https://github.com/addyosmani/web-quality-skills) for the *fix* side — performance, Core Web Vitals, accessibility, SEO, and best-practices skills that address what Lighthouse flags.

## License

MIT — see [LICENSE](LICENSE). Lighthouse itself is a separate project by Google, licensed Apache-2.0; this repo only teaches an agent how to use it.
