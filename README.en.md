[🇷🇺 Русский](README.md) · 🇬🇧 English

# AI assistant for web application testing

A workspace for QA engineers: clone the repository, open Claude Code, and start
prompting right away. The agent is already configured: it knows the company's QA
methodology (`docs/`), works from the team's checklists and templates, and can
push test cases to Test IT.

The company operates a matrix structure — many product teams on top of shared
standards. This template supports that out of the box: `docs/` holds the company's
shared standards (in git, updated centrally), `local/` holds your team's/product's
own adaptation (not in git, never conflicts with other teams). Details in
[local/README.md](local/README.md) *(Russian)*.

**Language of the conversation:** Russian by default. If you write to the agent in
English, or explicitly ask it to ("switch to English"), it continues in English —
including saved files — until you ask it to switch back. The methodology under
`docs/` / `checklists/` / `templates/` stays in its original language either way —
the agent translates it on the fly in its answers rather than keeping two sets
of files.

## Quick start

1. **Clone the repository** and open the folder in a terminal or VS Code.
2. **Install Claude Code** (if you haven't yet): [instructions](https://docs.anthropic.com/claude-code).
3. **Configure Test IT** (only needed for pushing test cases):
   ```
   copy .env.example .env
   ```
   then fill in `TESTIT_URL`, `TESTIT_TOKEN`, `TESTIT_PROJECT_ID` in `.env`.
4. **Drop your product's documentation** into `local/docs/` (`.md` format) — it takes
   priority over the shared standards and never leaves your machine (not in git).
   If your team has its own checklist or case template, put it in
   `local/checklists/` / `local/templates/` under the same file name as the shared one.
5. **Run** `claude` in the project folder and start prompting.

## What the agent can do

| Task | Example prompt |
|---|---|
| Requirements review against the checklist (per-item status, questions for the analyst, final verdict) | "Review the requirements in local/docs/auth-requirements.md" |
| Test cases (positive + negative) for every requirement | "Cover section 2's requirements with test cases" |
| Creating cases in Test IT (section = user story, suite = task) | "Push the cases from the last file to Test IT" |
| Answers about product documentation and QA methodology | "How long does the password-reset link stay valid?", "What's the procedure for a production incident?" |
| Saving context between sessions | "Save context" (also happens automatically after big tasks) |

The agent stores results under `results/`: requirements reports go to
`requirements-review/`, test cases go to `test-cases/`.

Per company process, the requirements report is published as a comment on the
YouTrack ticket — the agent has no such integration, so it prepares the text in a
file in a form you can paste into the comment as-is.

Beyond manual testing (code, automation, PRDs, deep research) the agent has
reference skills — they don't activate on their own, only if you explicitly ask
about something outside manual testing's scope.

## Four rules for working with the agent

1. **The agent doesn't make things up.** If the answer isn't in `local/` or `docs/`,
   it says so and asks a question. It marks its source: 🏠 — your local context,
   📁 — the company's shared standards, 🧠 — general knowledge.
2. **`local/` always takes priority over `docs/`.** If you put a file with the same
   name as a shared one into `local/docs/`, `local/checklists/`, or
   `local/templates/` — the agent uses your version. Nothing else to configure.
3. **Context lives for 2 days.** Session summaries are saved to `.context-cache/`
   and available to the agent in later sessions; they're auto-deleted after 2 days.
   Come back to a task the next day and just continue — the agent will remember.
4. **The more specific the prompt, the better the result.** Name the requirements
   file and section: "cover section 1 from local/docs/auth-requirements.md with
   cases" rather than "write some tests."

## Customizing for your team

You don't need to edit the company's shared standards (`docs/`, `checklists/`,
`templates/`) — they're centralized and updated for everyone at once. Put all your
own adaptations — product documentation, a different checklist, a different case
template — into `local/` (see [local/README.md](local/README.md) *(Russian)*); that
folder isn't in git, so your changes never conflict with other teams and are never
lost when the template updates.

How the agent works internally, and how to extend its skills, is in
[HOW-IT-WORKS.en.md](HOW-IT-WORKS.en.md).
