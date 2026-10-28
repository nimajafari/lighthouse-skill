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
- **Performance budgets** — enforce metric/size thresholds via Lighthouse CI assertions (the CLI's LightWallet `--budget-path` has been removed)
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

**Any agent, via the [`skills`](https://github.com/vercel-labs/skills) CLI** (detects the agents you have installed; works with 70+ including Antigravity, GitHub Copilot, Windsurf, OpenCode, Cline, Roo Code, Kiro, and Amp):

```bash
npx skills add nimajafari/lighthouse-skill

# or target specific agents, globally
npx skills add nimajafari/lighthouse-skill -a antigravity -a github-copilot -g
```

**Antigravity:** the repo ships an `.antigravity-plugin/plugin.json`, so the Antigravity CLI can install it as a plugin:

```bash
agy plugin install https://github.com/nimajafari/lighthouse-skill
```

Or copy the skill in by hand, to `.agents/skills/` in your workspace or
`~/.gemini/config/skills/` for every project (App and IDE). The CLI reads global skills from
`~/.gemini/antigravity-cli/skills/` instead.

**Cursor:** the repo ships a `.cursor-plugin/plugin.json`, so Cursor discovers the skill when the repo is added as a plugin.

**Gemini CLI:**

```bash
gemini extensions install https://github.com/nimajafari/lighthouse-skill
```

**Codex CLI** (v0.122+):

```bash
codex plugin marketplace add nimajafari/lighthouse-skill
```

**Other agents (manual):** every agent below reads the same `SKILL.md` folder, so copy
`skills/lighthouse/` into its skills directory:

| Agent | Project directory | Global directory |
|-------|-------------------|------------------|
| GitHub Copilot | `.agents/skills/` | `~/.copilot/skills/` |
| Windsurf | `.windsurf/skills/` | `~/.codeium/windsurf/skills/` |
| OpenCode | `.agents/skills/` | `~/.config/opencode/skills/` |
| Cline | `.agents/skills/` | `~/.agents/skills/` |
| Roo Code | `.roo/skills/` | `~/.roo/skills/` |
| Kiro | `.kiro/skills/` | `~/.kiro/skills/` (IDE only) |
| Amp | `.agents/skills/` | `~/.config/agents/skills/` |

```bash
# e.g. project-level, for any agent that reads .agents/skills/
mkdir -p .agents/skills && cp -r path/to/lighthouse-skill/skills/lighthouse .agents/skills/
```

Kiro's default agent discovers skills automatically. A **custom** Kiro agent only loads
them if you list them in its `resources` (e.g. `skill://.kiro/skills/*/SKILL.md`).

## Usage

The skill activates when your request matches its description. Examples:

```
Run Lighthouse on https://example.com and tell me what to fix first
```

```
Set up a performance budget and add Lighthouse CI to this repo
```

```
Check whether https://example.com is ready for AI agents (llms.txt, WebMCP)
```

```
Measure my homepage, then re-measure after the change to confirm it improved
```

## Requirements

- Node.js 22 (LTS) or later
- Lighthouse installed (`npm install -g lighthouse`, or run one-off via `npx lighthouse`)
- A Chrome/Chromium install (Lighthouse drives it; override with `CHROME_PATH`)
- `jq` for the wrapper script's JSON output

## Related

Pair with [addyosmani/web-quality-skills](https://github.com/addyosmani/web-quality-skills) for the *fix* side — performance, Core Web Vitals, accessibility, SEO, and best-practices skills that address what Lighthouse flags.

## License

MIT — see [LICENSE](LICENSE). Lighthouse itself is a separate project by Google, licensed Apache-2.0; this repo only teaches an agent how to use it.
