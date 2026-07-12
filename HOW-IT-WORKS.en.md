[🇷🇺 Русский](HOW-IT-WORKS.md) · 🇬🇧 English

# How the agent is built

A document for QA engineers and anyone extending this workspace.

## Layers of instructions

| Layer | Files | Audience |
|---|---|---|
| 1. Behavior rules | `CLAUDE.md` | The agent. Loaded every session: role, ban on making things up, answer-lookup order, token economy, project map |
| 2. Skills (procedures) | `.claude/skills/*/SKILL.md` | The agent. Step-by-step algorithms for specific tasks; wired in automatically when a prompt matches a skill's job |
| 3. Guides | `README.md`, `HOW-IT-WORKS.md` | QA engineers |

## The agent's skills

The core loop — the company's QA process:

| Skill | What it does | Relies on |
|---|---|---|
| `testing-requirements` | Runs requirements through every checklist item (the checklist itself defines the section structure and the final report format — currently sections 0+А–Ж, statuses ✅⚠️❌➖, blocking items 🔴); mandatory self-check before handoff → `results/requirements-review/` | `checklists/requirements-checklist.md`, `templates/Otchet-o-testirovanii-trebovanij.md` |
| `test-case-design` | Builds a requirements registry using the BT/FT scheme (the same one the checklist uses); for each FT — positive and negative cases (TK-<FT>.<n>) per company rules; mandatory self-check before handoff → `results/test-cases/` | `templates/test-case-template.md`, `templates/test-case-example.md` (trace-table format), `docs/Napisanie-test-kejsov.md` |
| `testit-sync` | Creates cases in Test IT via REST API: section = user story, suite = task (checks the connection first, then confirms the plan with the tester) | `.env`, `docs/Testirovanie-Shift-Left.md` |
| `save-context` | Saves a session summary to `.context-cache/` | — |

### Self-check before handoff

The idea comes from [claude-code-orchestrator-kit](https://github.com/maslennikov-ig/claude-code-orchestrator-kit)
(there it's `validate-report-file`/`run-quality-gate` for code) and was adapted for
manual QA: `testing-requirements` and `test-case-design` don't hand the result to
the tester right away — first they mechanically check the draft against the
specification (are all checklist items covered, does every requirement have both a
positive and a negative case, is there no hard-coded static test data, etc.) and
fix whatever they find. A short "Agent self-check" block stays at the end of the
saved file — not meant to be copied into YouTrack/Test IT, it's there purely for the
tester's visibility.

Reference skills are large adapted reference material (originally written for a
different platform, Perplexity Computer, and converted into Claude Code's format).
The agent uses them only when the tester explicitly steps outside manual testing,
never proactively:

| Skill | When it applies |
|---|---|
| `dev-engineering` | Code, architecture, automation, CI/CD, security |
| `product-management` | PRDs, acceptance criteria, prioritization, roadmapping |
| `research-knowledge` | Deep research, data analysis, source evaluation |
| `token-efficient` | Background response style — brevity, no filler (duplicates part of CLAUDE.md's rules as a detailed reference) |

Each such file opens with a note about the adaptation: commands like
`python scripts/*.py` inside are illustrative patterns from the original source —
they don't exist in this repository and shouldn't be invoked.

## The local/ vs docs/ model (matrix structure)

The company runs a matrix QA structure (`docs/Operacionnaya-model-QA.md`, sections
5, 7, 8): central QA sets shared standards, product teams adapt them to their own
domain. That's reflected in two context layers:

| Layer | Folders | In git? | Who fills it in |
|---|---|---|---|
| Company-wide standards | `docs/`, `checklists/`, `templates/` | Yes | Central QA |
| Team-local adaptation | `local/docs/`, `local/checklists/`, `local/templates/` | No (except README.md) | Product team/project |

Override rule: a file under `local/...` with the **same name** as a shared one
fully replaces the shared one for that team when the agent reads it. A file with a
new name is simply added to the context (e.g., a specific product's documentation).
Details and rationale are in `local/README.md` *(Russian)*.

This lets different product teams, projects, and even different companies clone the
same template, pull in shared methodology updates, and never clash with each
other's local adaptations.

## Answer lookup order (local context)

For any question, the agent looks for an answer in this order:

1. `local/docs/` — this product team's own documentation and adaptations (priority);
2. `docs/` — the company's shared standards (if `local/docs/` has no matching file/answer), see `docs/README.md`;
3. `.context-cache/` — session summaries from the last 2 days;
4. General knowledge (testing, development, management) — flagged with 🧠;
5. A question to the tester — if the answer is nowhere. The agent is not allowed to make things up.

Same logic applies to the checklist and templates: `local/checklists/` /
`local/templates/` are checked before `checklists/` / `templates/` — this is already
built into the `testing-requirements` and `test-case-design` skills.

## Limitation: no YouTrack/Teams integration

The company's real workflow (`docs/Testirovanie-Shift-Left.md`,
`docs/Testirovanie-Shift-Right.md`) expects reports to be published as a comment on
the YouTrack ticket, with communication happening in Teams. The agent only
integrates with Test IT (via `.env`). It prepares requirements reports and other
artifacts as files under `results/`, formatted so you can paste them into YouTrack
as-is — the tester does the actual posting by hand.

## Session context cache

- After a big task (or on the "save context" prompt) the agent writes a short
  summary to `.context-cache/`: what was done, decisions made, open questions.
- At the start of every session, the `SessionStart` hook (`.claude/settings.json`)
  runs `.claude/scripts/clean-cache.ps1`, which deletes files older than 2 days.
- The cache is local (in `.gitignore`) — each tester has their own.
- The cleanup script is written for Windows PowerShell; macOS/Linux needs `pwsh`
  or a shell-equivalent replacement for the hook command.

## Conversation language (RU by default, switchable to EN)

`.claude/settings.json` sets `language: "russian"` as the harness's default
preference, and `CLAUDE.md` adds an explicit switching rule: if the tester writes
in English, or asks directly ("switch to English"), the agent continues the
conversation and writes result files (`results/`, `.context-cache/`) in English,
until asked to switch back to Russian.

The two top-level guide documents (README/HOW-IT-WORKS) were translated as
separate files (`README.en.md`, `HOW-IT-WORKS.en.md`) — this is static
human-facing documentation, and duplicating it is simpler than translating on the
fly. The methodology (`docs/`, `checklists/`, `templates/`), on the other hand,
stays a **single source in its original language** — we deliberately did not create
`docs-en/`/`checklists-en/`: the agent understands Russian input perfectly well
regardless of what language it answers in, and parallel copies of the methodology
would mean double maintenance and a real risk of the two versions drifting apart.
The English copy exists only for the top-level guides, not for the checklist or
templates — those are edited in Russian only.

## .claude/settings.json

Besides the cache-cleanup hook, the file sets:
- `language: "russian"` — the harness's default response language (a soft
  preference — `CLAUDE.md` explicitly allows switching to English on request, see
  the section above);
- `autoUpdatesChannel: "stable"` — testers aren't developers, they don't need the
  bleeding edge;
- `permissions.deny: ["Read(.env)"]` — the agent is forbidden from reading `.env`
  with the Read tool. The Test IT token must only end up in PowerShell environment
  variables, never in text the model sees (see below and `testit-sync/SKILL.md`).

**An important gotcha for any skill that talks to an external API via `.env`:**
PowerShell state (environment variables, functions) **is not preserved between
separate tool invocations** — only the working directory is. That means `.env`
must be loaded into environment variables again at the start of **every**
PowerShell command that hits the API, not just once at the start of the skill.
`testit-sync` already accounts for this; if you add a new integration, repeat the
same pattern rather than relying on "loaded it once at the start."

## Token economy and accuracy

Baked into `CLAUDE.md` as mandatory rules:
- search files (Grep) instead of reading them whole; read large documents in parts;
- bulky results go into files under `results/`, chat only gets a summary;
- every claim about requirements is backed by a `file:line` reference;
- ambiguity is a reason to ask a question, not to silently interpret.

## How to add a new capability (load testing, automation, …)

1. Create a `.claude/skills/<skill-name>/` folder with a `SKILL.md` file.
2. In the frontmatter: `name` and `description` — the agent decides when to apply
   the skill based on `description`, so list the typical prompt phrasings in it.
3. In the body: inputs, step-by-step algorithm, output format, rules. Look at the
   existing skills as a model.
4. Put supporting files (templates, checklists) into `templates/` or `checklists/`
   and reference them from the skill by relative path. If the file might differ
   across product teams, teach the skill to check for a same-named file in
   `local/templates/` / `local/checklists/` first (see the `local/` vs `docs/`
   model above).
5. Add a line about the new process to the "Workflows" table in `CLAUDE.md` and to
   the capabilities table in `README.md`.

## Project structure

```
project-root/
├── CLAUDE.md                  # agent instructions (layer 1)
├── README.md                  # quick start for QA engineers (RU)
├── README.en.md                #   English version
├── HOW-IT-WORKS.md            # this file (RU)
├── HOW-IT-WORKS.en.md          #   English version
├── .env.example               # Test IT secrets sample (.env is in .gitignore)
├── .claude/
│   ├── settings.json          # cache auto-cleanup hook
│   ├── scripts/clean-cache.ps1
│   └── skills/                # the agent's skills (layer 2)
│       ├── testing-requirements/
│       ├── test-case-design/
│       ├── testit-sync/
│       ├── save-context/
│       ├── dev-engineering/       # reference, outside the manual-QA loop
│       ├── product-management/    # reference
│       ├── research-knowledge/    # reference
│       └── token-efficient/       # reference, response style
├── docs/                      # company-wide standards (QA methodology) — RU only
├── checklists/                # company-wide checklist — RU only
├── templates/                 # company-wide templates — RU only
├── local/                     # NOT in git (except README.md) — product team adaptation
│   ├── docs/                  #   this product's documentation
│   ├── checklists/            #   checklist override
│   └── templates/             #   template override
├── results/                   # the agent's output
│   ├── requirements-review/
│   └── test-cases/
└── .context-cache/            # session cache, 2-day TTL (in .gitignore)
```
