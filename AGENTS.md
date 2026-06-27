# AGENTS.md

Guidance for AI coding agents working in this repository.

## Project overview

A single [Agent Skill](https://agentskills.io/specification) that teaches an agent to run [Google Lighthouse](https://github.com/GoogleChrome/lighthouse) — CLI, performance budgets, CI, and the programmatic API — to measure and verify web quality.

## Structure

```
lighthouse-skill/
├── README.md
├── LICENSE
├── .claude-plugin/            # Claude Code plugin + marketplace manifests
└── skills/
    └── lighthouse/
        ├── SKILL.md           # main instructions (keep under 500 lines)
        ├── scripts/
        │   └── run-lighthouse.sh
        └── references/
            ├── CI.md
            └── PROGRAMMATIC-API.md
```

## Conventions

- **SKILL.md** stays under 500 lines; push deep/look-up material into `references/`.
- **Descriptions** include trigger phrases so the skill activates on the right prompts.
- **Code examples** use ❌ bad / ✅ good where it clarifies, and prefer copy-pasteable commands.
- **Scripts** follow: `#!/bin/bash` + `set -euo pipefail`; human logs to **stderr**, machine-readable JSON to **stdout**; cleanup trap for temp files; document dependencies (`jq`, Node/`npx`).

## Accuracy notes

- Lighthouse evolves. Audit IDs and metric weights shift between major versions (see the v13 Insight Audits note in SKILL.md). When editing, prefer linking to upstream docs over hardcoding numbers that drift.
- Keep the lab-vs-field distinction prominent — Lighthouse is a lab tool; INP and real-user data come from the field (CrUX / `web-vitals`).

## Testing changes

1. Validate the YAML frontmatter in `SKILL.md`.
2. `shellcheck skills/lighthouse/scripts/run-lighthouse.sh`.
3. Smoke-test the script against a real URL: `skills/lighthouse/scripts/run-lighthouse.sh https://example.com 1`.
4. Confirm all referenced files exist and links resolve.
