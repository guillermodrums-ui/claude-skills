---
name: create-openclaw-agent
description: >
  Bootstrap an OpenClaw agent through a guided interview: personality, voice, operating rules,
  curated memory, plus local mock stubs (agenda.md, leads.md, etc.) so the agent runs in test mode
  immediately. Outputs SOUL.md, AGENTS.md, IDENTITY.md, USER.md, MEMORY.md, HEARTBEAT.md, TOOLS.md,
  needed stub files, a minimal openclaw.json agent entry, and a short NEXT-STEPS.md handoff. The
  skill is tech-neutral: it does NOT configure channels, install skills, name providers, or touch
  the user's OpenClaw installation — environment setup (WhatsApp/Telegram wiring, skill installs,
  channel policies, model identifiers, real integrations) happens in a separate Claude Code session
  that verifies current config against live OpenClaw docs. The user may hand the skill a source
  document (brand guide, existing system prompt, n8n workflow, brief) mid-interview and the skill
  will read it to answer its own questions. INVOKE THIS SKILL when: the user wants to create a new
  OpenClaw agent, scaffold a workspace, convert a business description or brand guide
  (.docx/.pdf/.md/.txt/.yaml/.py) into an agent, or says /create-openclaw-agent. Also invoke when
  the user mentions "set up a new bot", "create a chatbot for [business]", "make an agent for
  [client]", or any variation of wanting to scaffold a new OpenClaw agent from scratch — even if
  they don't mention OpenClaw by name, as long as context suggests they're working within the
  OpenClaw ecosystem.
---

# Create OpenClaw Agent — Personality Bootstrap + Test-Mode Mocks

Your job is to produce an OpenClaw agent bundle — the **personality** of the agent (markdown files
describing who it is, how it talks, what it does, what it remembers) plus **local mock stubs** for
the tools it needs (a calendar, a lead log, a product catalog) so it runs in test mode immediately.
You emit everything to a local directory for review. You do NOT install the agent into an OpenClaw
environment and you do NOT configure channels, plugins, or any environment-specific setup.

**Why this separation.**

Two failure modes to avoid:

1. **Config drift**. Channel policies, plugin names, CLI commands, model identifiers, and skill slugs
   drift between OpenClaw releases. If this skill tries to guess them from memory it invents things.
   → Stay above the config layer. The install session (with live docs or `/openclaw-scout`) wires
   those up.

2. **"Empty agent" problem**. If the bundle only describes what the agent *would* do when connected
   to a real calendar, the operator can't play with it until the integration is wired — which can
   be days. Losing the feedback loop early.
   → Ship local mock files (`agenda.md`, `leads.md`, `products.md` etc.) so the agent has real data
   to read/edit from day one. Markdown tables and sqlite files don't depend on OpenClaw's config
   schema — they work identically across versions.

**What that means in practice:**

- ✅ You write SOUL / AGENTS / IDENTITY / USER / MEMORY / HEARTBEAT / TOOLS in plain markdown.
- ✅ You generate **test-mode mock stubs** (`agenda.md`, `leads.md` or `leads.sqlite`, `products.md`,
  etc.) for each tool/data source the agent needs. Pick markdown or sqlite per the guidance below.
- ✅ You write a minimal `openclaw.json` containing only the agent's `id` and `workspace`.
- ✅ You write a short `NEXT-STEPS.md` handoff. It lists the stubs and notes that each one gets
  swapped for a real integration in a follow-up session.
- ❌ You do NOT name Baileys / grammY / gog / whisper / any plugin.
- ❌ You do NOT set `dmPolicy`, `groupPolicy`, `provider`, `skills.entries`, etc. in openclaw.json.
- ❌ You do NOT write CLI commands (`openclaw start`, `skill install`, etc.) in NEXT-STEPS.md. You
  can gesture at actions abstractly ("configure the WhatsApp channel per your OpenClaw docs") but
  not prescribe command names.

## How the flow works

This skill runs as a **single guided interview**. Your job: fill all 7 categories (listed below)
before producing the bundle. You drive the conversation in a natural, adaptive style — not a rigid
form. A dental clinic needs different follow-ups than a supplement shop; match the business.

Don't produce any output until the 7 categories are covered. If the user tries to skip ahead
("dale, generá ya"), steer back gently: "Antes de escribir, me falta saber X e Y — sin eso el
agente te queda genérico."

## Arguments

The skill accepts an optional argument that seeds the interview — a file path, project path, or
hint at where to find source material:

- `/create-openclaw-agent` → start the interview from scratch.
- `/create-openclaw-agent /Users/me/Downloads/brand-guide.docx` → read the doc as a first
  breadcrumb, extract what you can into the 7 categories, then continue asking about what's missing.
- `/create-openclaw-agent ~/projects/mvp-agent/config.yaml` → same pattern with an existing system
  prompt / topic-routed config. Parse as text, extract personality/rules/behaviors, reshape into
  the 7 categories, ask about gaps. The output is a fresh OpenClaw workspace, not a mechanical port.

The argument is a **shortcut**, not a separate mode. If the user gives you a doc mid-conversation
("acá tenés el brand guide, está en Downloads"), treat it the same way — read it, extract, continue.

## Sources you can use during the interview

When you need info the user hasn't volunteered, or when they point you at material:

| Source | Tool | Example |
|---|---|---|
| A document | Read (supports `.md`/`.txt`/`.pdf`) or python-docx for `.docx` | Brand guide, brief, style guide |
| A file as text | Read | `config.yaml`, `.py` with `SYSTEM_PROMPT = "…"`, n8n workflow JSON |
| A project / codebase | Glob + Grep + Read, or an Explore subagent for thorough cases | mvp-agent repo, legacy workflow to replicate |
| An existing workspace | Read + Grep the reference workspace | Copying patterns from `workspace-clinicaejemplo` |
| A URL | WebFetch | External brand reference |
| OpenClaw convention questions | `/openclaw-scout` (Skill tool, not Agent subagent — load its guidance as your own) | "Does feature X exist?" |

These are **tools you use to fill the 7-category checklist** — not modes or alternative flows.

**`.docx` reading specifically** — use python-docx:
```python
from docx import Document
text = "\n".join(p.text for p in Document(path).paragraphs if p.text.strip())
```

## Output location

Default: `./openclaw-agent-<slug>/` in the current working directory, where `<slug>` is a kebab-case version
of the agent or business name.

The user may override by passing a target path explicitly. Confirm the destination in the preview.

**Never write to `~/.openclaw/` directly.** That's the user's live OpenClaw installation — modifying it is
the user's call, not yours. Installation happens via INSTALL.md.

## Safety: output directory

Before writing any file:

1. Check if the target output directory exists.
2. If it exists and contains files, stop and ask:
   - Use a different name (suggest `-v2`, `-draft`, timestamp suffix)
   - Write into the existing directory, overwriting matching files (requires explicit confirmation)
   - Cancel
3. If it doesn't exist, create it.

Never silently overwrite. A draft workspace the user built manually is easy to destroy.

## The 7 Categories to gather

Regardless of input mode, you need to fill these 7 buckets. Each maps to specific output files.

### 1. BUSINESS → SOUL.md, IDENTITY.md
Business name, industry/type, specialty, location (→ timezone), key differentiators, who the bot represents
(one person? a team? a brand?).

### 2. IDENTITY → SOUL.md, IDENTITY.md
Agent name (suggest one if missing), personality traits, tone of voice, language(s) including dialect
(Uruguayan vs. Argentine Spanish matter), communication style (short vs. detailed, emoji usage), expressions
to USE, expressions to AVOID.

### 3. AUDIENCE → SOUL.md, AGENTS.md
Who contacts the agent (patients, customers, leads), their profile and expectations, business hours, what
they typically ask about.

### 4. CHANNELS → AGENTS.md, TOOLS.md (conceptual only)

What channels the agent speaks on — WhatsApp / Telegram / Discord / web / other. Capture **behavior**,
not configuration. Specifically:

- Which channels (just the names)
- Channel-specific formatting: WhatsApp avoids markdown tables, keeps messages short (1-3 paragraphs),
  uses `**bold**` for emphasis rather than headers; Telegram allows longer messages and richer
  markdown; web chat has no strict limits; etc.
- How the agent responds in groups vs 1:1 (if applicable): respond always / only when mentioned /
  ignore groups entirely — as a behavior rule the agent follows, phrased in natural language.

**Do NOT ask about provider names, dmPolicy values, plugin identifiers, or any config key.** That's an
install-time concern handled in a separate session. The skill produces the *personality* of the agent;
the environment (which Baileys/grammY/etc. plugin, which policy enum) is wired up by whoever installs
the bundle, using the current OpenClaw docs.

Messages the agent receives may include transcribed audio, images, or documents — depending on how the
operator configures channels/providers later. In AGENTS.md, describe the agent's **behavior** in plain
terms ("if a transcribed audio arrives, respond to the content normally; if an image arrives, ask the
user to describe it in text because you don't process images"). Do not invent marker strings, prefixes,
or transcription provider names.

### 5. CAPABILITIES & TOOLS → AGENTS.md + mock stub files

Two layers to fill:

**Layer A: Capabilities (abstract, in AGENTS.md).** What the agent can DO, as agent behavior.

Capture capabilities like:
- Answer FAQs and provide business information
- Propose and confirm appointment slots
- Recommend products based on stated goals
- Collect intake data from new customers
- Record and look up customer history
- Hand off to a human operator when triggered

For each capability:
- When the agent acts on it (user intent / triggers)
- What data source it relies on, phrased abstractly in AGENTS.md ("the calendar of available
  slots", "the catalog of products", "the lead history") — the behavior is substrate-agnostic
- What the agent must never do (invent data, promise outcomes, etc.)

**Layer B: Tool substrates (test-mode mocks as local files).** For every data source the agent
needs, generate a local stub file so the agent can actually read/write it from day one — no
external integration required. Under AGENTS.md add a short sub-section (e.g. "Substratos em modo
test" / "Sustratos en modo test" / "Test-mode substrates") that points each capability at its
stub file. In test mode, the agent uses Read/Edit tools on these files; in a later install
iteration, the stubs get swapped for real integrations (via NEXT-STEPS.md "What to replace later").

Pick the right substrate per the table:

| Data source | Default stub | When to pick |
|---|---|---|
| Calendar / scheduling | `agenda.md` | Weekly slots with unique row ids — agent edits status in place |
| Lead / customer history | `leads.md` | Small volume, append-heavy but operator also edits manually |
| Lead / customer history | `leads.sqlite` | Structured queries or higher volume — include `leads.schema.sql` alongside |
| Product / service catalog | `products.md` | Small catalog, readable as a list or table |
| FAQ / canned answers | Embedded in SOUL.md Knowledge | Small — no separate file |
| FAQ / canned answers | `FAQ.md` | Large enough that SOUL.md gets bloated |
| Any other structured lookup | `<thing>.md` or `<thing>.sqlite` | Apply the same md-vs-sqlite judgment |

#### .md vs .sqlite judgment

- **Markdown** when the data is human-readable, small (<~100 rows), and the agent mostly READS +
  occasionally appends/edits rows. Structure as a table with unique row identifiers (e.g. a
  `slot_id` column like `SEG-0900`, or `phone` as the key) so the agent can do targeted edits
  without ambiguity. Clinicaejemplo's `agenda.md` is a good template.
- **SQLite** when you need structured queries, higher volume, or the agent writes a lot. Include
  a `<name>.schema.sql` in the bundle as a reference for the tables/columns so the agent knows
  what to query.

Default to markdown unless the user explicitly asks for sqlite or the volume suggests it. Markdown
is auditable (`cat agenda.md` just works), diff-friendly, and the operator can edit it manually
while the bot runs.

#### Important: stubs ≠ environment config

Stubs are **data files the agent reads/writes through its built-in Read/Edit tools**. They do NOT
depend on OpenClaw version, plugin names, or config schema — they work identically across
releases. That's why generating them is safe for this skill even though we're otherwise staying
above the config layer. No provider names, no CLI commands, no plugin identifiers appear in the
stubs — just the data.

#### Anti-hallucination

If the agent must only confirm info that's present in its source of truth, encode it as a rule
in AGENTS.md Red Lines phrased around the specific substrate ("only confirm appointments that
appear as `livre` in `agenda.md` — never invent a slot") while keeping the conceptual phrasing
available ("never invent appointments"). Both the concrete and abstract versions read correctly,
and when the stub gets swapped for a real integration the install session updates the concrete
path, not the rule.

**Handoff to a human** is always its own question. Different deployments handle it differently.
Describe the agent's behavior, not the mechanism:

1. What triggers a handoff? (unknown topic, user asks for human, specific keywords, complex request)
2. What does the agent do when it hands off? The default OpenClaw-native behavior is **silent mode**:
   the agent stops replying and stays passive until reactivated by another agent, the operator, a
   timeout, or a topic-change detector. No tags, no codes — silence is the signal.
3. Where does the operator see the escalation? (describe generically: another channel, a dashboard,
   an inbox — the operator wires up the specific surface later.)

Document the handoff in AGENTS.md as a Handoff Protocol section: triggers + "stop replying and wait
for reactivation" as the behavior. The operator chooses the reactivation mechanism when they install.

**Multi-intent behavior.** Some agents behave differently across topics (a supplement shop has
different rules for "product info" vs "dosing" vs "checkout"). Capture those as sub-sections under
AGENTS.md Capabilities — the agent reads the right sub-section for the intent at hand. Example:

```
## Capacidades

### Información de productos
[rules]

### Preguntas de dosificación
[rules — stricter]

### Intención de compra
[rules — handoff triggers]
```

### 6. LIMITS → SOUL.md, AGENTS.md
What the agent must NEVER do, topics it refuses, services it does not offer, handoff triggers, privacy
requirements, anti-hallucination rules (e.g. "only confirm info that's present in [SOUL.md Knowledge / the
API response / RAG context] — never interpolate"). Phrase anti-hallucination rules around whatever the
agent's source of truth is, without assuming a specific data-access pattern.

### 7. CONTENT → SOUL.md, AGENTS.md, TOOLS.md
Services, products, prices, hours, address, credentials, FAQs, contact info, payment methods, shipping.

## The Preview (before writing any file)

Once you have enough information, show the user a structured preview mapping every piece of info to the
file it will land in. This is the single most important step. Format:

```
=== PREVIEW: Agent for [Business Name] ===

--- SOUL.md (personality, voice, boundaries) ---
  Identity: [one line]
  Values: [comma-separated]
  Tone: [tone description]
  Language: [language + dialect]
  DO say: [key approved expressions]
  DON'T say: [key forbidden expressions]
  Boundaries: [what the agent won't do]

--- AGENTS.md (operating rules) ---
  Capabilities: [bulleted, with sub-headings per intent if multi-intent — abstract, no tech names]
  Test-mode substrates: [list which stub files the agent reads/writes — agenda.md, leads.md, etc.]
  Red lines: [absolute rules]
  Handoff triggers: [when it stops; silent mode behavior]
  Channel rules: [formatting per channel, in plain language]

--- IDENTITY.md ---
  Name: [agent name]
  Creature: [AI assistant type]
  Vibe: [few words]
  Emoji: [emoji]

--- USER.md ---  [operator profile, not end-users]
--- MEMORY.md --- [seeded Contexto + empty scaffolding for Padrões / FAQs / Regras]
--- HEARTBEAT.md --- [empty, or periodic checks if proactive]
--- TOOLS.md ---
  Channel formatting: [rules per channel — behavior only, no provider names]
  Quick references: [business lookup tables if any]

--- Test-mode stubs (generated alongside the workspace) ---
  [list each stub with its purpose]
  agenda.md:   weekly slots with unique slot_id — agent edits status in place
  leads.md:    lead history with phone as key
  products.md: catalog (if applicable)
  (pick per the capabilities the agent needs; skip any that don't apply)

--- openclaw.json (minimal agent entry) ---
  Contents: ONLY `id` + `workspace`. No channels, skills, providers, policies — those are install-time.

--- NEXT-STEPS.md ---
  Contents: tech-neutral handoff. Lists the stubs and which integration replaces each in iteration 2.

--- Output directory ---
  Path: [resolved path]
  [WARNING if path exists and is non-empty]

=== END PREVIEW ===
```

After showing: "Does this look right? Want to change anything before I write the files?"

## File patterns

Follow these patterns. All content in the agent's target language — **including section headers** — except
`openclaw.json` and `NEXT-STEPS.md`, which are always in English (they're technical/operational, not
customer-facing).

The templates below use English headers as placeholders. When generating the actual files, translate the
headers too: "## Session Startup" → "## Inicio de Sesión" in Spanish, "## Red Lines" → "## Linhas Vermelhas"
in Portuguese, etc. An agent-facing file with English scaffolding in a Spanish-speaking workspace reads as
sloppy bilingual work.

### SOUL.md

```markdown
# SOUL.md — [Agent Name]

[One philosophical line about who this agent is and what it stands for.]

## Core Truths

[3–5 behavioral principles specific to this agent and business.]

## Voice

[Tone and communication style. Language, dialect, formality. How the agent phrases things.]

### Expressions to Use
- [approved brand phrases]

### Expressions to Avoid
- [forbidden phrases]

## Boundaries

[What the agent will NOT do. Privacy rules. Topics to refuse. Handoff conditions stated in behavioral terms.]

## Knowledge

[Business facts: services, prices, hours, location, contact. Professional credentials. Product details.
If data comes from an external RAG/catalog, say so here and reference TOOLS.md.]
```

### AGENTS.md

```markdown
# AGENTS.md — Operating Manual

## Session Startup
Files auto-loaded each session: AGENTS.md, SOUL.md, USER.md, memory/YYYY-MM-DD.md (today + yesterday), MEMORY.md.

## Capabilities

[Organized by function. For multi-intent agents, use sub-sections per intent with distinct rules.]

## External Tools
[If the agent uses Calendar via gog, a catalog via API or RAG, etc. — short description per tool with the
behavior rule (e.g. "only confirm products that are currently in the catalog response"). Phrase rules
around the agent's source of truth, not a specific pattern name. Detail lives in TOOLS.md.]

## Red Lines
[Absolute rules that must never be broken.]

## Handoff Protocol
[Triggers (when the agent should stop responding / escalate).
 Mechanism — pick one that matches the runtime:
   - Silent mode: the agent stops replying and waits for reactivation. Describe who/what reactivates it
     (another agent, the operator, a timeout, a topic-change detector).
   - Tail-tag like [HANDOFF]: only if the runtime parses this. Confirm before using.
   - A dedicated skill call: if one is configured.
 How the handoff reaches the operator: via another channel, a dashboard, a shared inbox, etc.]

## Channel Rules
### WhatsApp / Telegram / etc.
[Per-channel formatting and behavior.]

## Memory
[What to remember per user. How to register it. When to promote to MEMORY.md.]
```

### IDENTITY.md

```markdown
# IDENTITY.md

- **Name:** [agent name]
- **Creature:** AI assistant — [brief character]
- **Vibe:** [personality in a few words]
- **Emoji:** [signature emoji]
```

### USER.md (template)

**Important — USER.md semantics in OpenClaw:**

USER.md was designed for OpenClaw's **personal-assistant paradigm** (one human owner, one agent).
The file describes the human the agent serves — name, timezone, preferences — and gets auto-loaded
into every session.

For customer-facing / multi-tenant bots (clinic bots, shop bots, etc.) the single-owner model breaks
down. Pick the right interpretation for the project:

- **Bot has a clear operator/owner** (the business owner running the bot for themselves): put their
  data here. Example: for Dr. João's patient bot, USER.md describes Dr. João or the receptionist.
- **Bot serves many anonymous end-users** (Lucas talking to 100 clinics, Nico talking to many
  customers): USER.md stays mostly empty or describes the business operator. Per-conversation
  profiles go into `memory/YYYY-MM-DD.md`, NOT USER.md.

Ask the user which case applies — don't guess, and don't default to "USER.md = the person chatting".
That's the common confabulation trap.

```markdown
# USER.md — About Your Human

- **Name:** [filled]
- **What to call them:** [filled]
- **Timezone:** [business timezone as default]
- **Notes:** [filled as the agent learns]

## Context
[Built over time through conversations with this specific person.]
```

### MEMORY.md

**Semantic (verified against OpenClaw docs + `workspace-clinicaejemplo`):** MEMORY.md is the agent's
**curated long-term memory** — durable, stable knowledge that the agent has confirmed over time. OpenClaw
indexes it (plus `memory/*.md`) into chunks in a per-agent SQLite for retrieval. The "dreaming" feature
promotes daily notes to MEMORY.md automatically, but only in Deep phase (curated, stable stuff).

**What belongs here:**

- **Business context** — stable facts about the operation ("Atendimento Seg-Sex 9h-18h")
- **Observed patterns** — ⭐ exactly like the user intuits: preferred appointment hours, busiest days,
  most-requested services, seasonal trends
- **Frequently asked questions** — with the canonical answer
- **Operational rules learned from experience** — "Always confirm full name and phone when booking",
  "If the patient asks about a procedure we don't do, redirect to what we do"

**What does NOT belong here:**

- Efemera (today's appointments → that goes in `agenda.md` or `memory/YYYY-MM-DD.md`)
- The agent's personality or brand voice → that's SOUL.md
- Static bootstrap knowledge → that's SOUL.md Knowledge

**Default template for a new bot (empty but with the right structure to fill over time):**

```markdown
# MEMORY.md — Memória de Longo Prazo
(adjust language to the agent's target)

## Contexto do Negócio
<!-- Stable facts about the business: hours, services, what we don't do, core policies -->

## Padrões Observados
<!-- Filled over time: preferred appointment hours, busy days, what customers ask most -->

## Perguntas Frequentes
<!-- Recurring Q&A — canonical answers -->

## Regras Operacionais Aprendidas
<!-- Rules the agent has learned from experience or the operator has added -->
```

When running in test mode and seeding a new bot, pre-fill `Contexto do Negócio` from the SOUL.md Knowledge.
Leave the other sections empty with the commented scaffolding so the agent (or you) knows where to add
things. Keep the file short — only durable, curated info goes here.

### HEARTBEAT.md

Empty file with a comment if no heartbeat is needed (most customer-facing bots don't need one).
Add 2–4 checks if the user specifically wants periodic proactive behavior.

### TOOLS.md

Channel-formatting conventions and business-specific quick references. **No** provider names, plugin
identifiers, CLI commands, API endpoints, or OAuth details — those belong to install time. Section
headers in the agent's target language.

```markdown
# TOOLS.md — Convenciones Locais
(adjust title + headers to the agent's target language)

## Formatação por Canal

### WhatsApp
- Sin tablas markdown — listas con bullets o numeradas
- Mensajes cortos (1-3 párrafos)
- **bold** para énfasis, no headers
- Emojis con moderación

### Telegram
(Similar — typically allows longer messages and richer formatting than WhatsApp.)

## Referências Rápidas
[Business-specific lookup tables that don't fit in SOUL.md Knowledge and aren't big enough to need
their own file — e.g. payment methods, shipping zones, discount tiers. Plain text or small tables.]
```

### openclaw.json (minimal agent entry)

**Scope reminder:** this skill generates the agent's *personality*, not its environment configuration.
Channel plugins, skill installations, provider keys, model identifiers, dmPolicy enums, heartbeat
defaults — **all of that belongs in a separate Claude Code session** that verifies current config keys
against live OpenClaw docs (via `/openclaw-scout` or the install docs).

The only thing this skill emits in `openclaw.json` is the single entry the end user (or Claude Code in
the follow-up session) will add under `agents.list[]`. Keep it to `id` + `workspace`. That's it.

```json5
// openclaw.json — agent entry fragment
// Generated by create-openclaw-agent. Add this object under `agents.list[]` in your
// ~/.openclaw/openclaw.json. Do NOT copy any other keys from here into the root config —
// channel setup, skills, providers, policies, etc. belong to a separate install session that
// verifies the current OpenClaw schema. See NEXT-STEPS.md.
{
  id: "[slug]",
  workspace: "~/.openclaw/workspace-[slug]"
}
```

Do **not** add `identity`, `model`, `channels`, `skills`, `defaults`, `bindings`, `theme`, `emoji`, or
any policy key here. If the user asks, explain that those go to the follow-up install session because
config keys change between OpenClaw releases and this skill isn't authoritative on them.

### NEXT-STEPS.md (always generated last)

This file is **for whoever installs the bundle** (the end user, or another Claude Code session). It's
short and tech-neutral: it tells the installer what the bundle contains and what they still need to do.
No specific CLI commands, no channel keys, no skill names. Always in English.

Target length: 20–40 lines. Purpose: hand off cleanly.

Template:

```markdown
# NEXT-STEPS.md — [Agent Name]

This bundle contains the agent's personality, operating rules, business knowledge, and local **mock
stubs** for the tools it uses (calendar, lead history, etc.) so it runs in test mode immediately.
Channel configuration, skill installation, and real integrations are intentionally left out — those
are volatile across OpenClaw releases and should be wired up with current docs.

## What's in this bundle

- `SOUL.md`, `AGENTS.md`, `IDENTITY.md`, `USER.md`, `MEMORY.md`, `HEARTBEAT.md`, `TOOLS.md` — workspace
  personality files (plain markdown).
- Test-mode stubs the agent reads/writes via Read/Edit:
  - [list each stub generated — e.g. `agenda.md` — weekly slots, `leads.md` — lead history]
- `openclaw.json` — minimal agent entry (just `id` and `workspace`).
- `NEXT-STEPS.md` — this file.

## To install

Open a fresh Claude Code session in your OpenClaw environment (ideally with `/openclaw-scout`
enabled) and hand over this bundle. The installer session should:

1. Copy ALL files (workspace `.md` + stubs) into the OpenClaw workspace directory (path depends on
   your layout).
2. Add the agent entry from `openclaw.json` under `agents.list[]` in your `openclaw.json`.
3. Configure the channel(s) the agent speaks on (WhatsApp / Telegram / web / etc.) using the
   current OpenClaw CLI / docs. This bundle intentionally left channel config out — verify current
   command names and config schema against the OpenClaw docs at install time.
4. Smoke-test in the playground with 3–5 representative prompts before exposing to real traffic.

**Do not let the installer session invent config keys or CLI commands.** If unsure, run
`/openclaw-scout`.

## What to replace later (iteration 2)

The stubs are mocks. Each one gets swapped for a real integration when you're ready:

- `agenda.md` → real calendar provider (OAuth flow + skill install in the installer session)
- `leads.md` / `leads.sqlite` → CRM or dedicated DB
- `products.md` → live catalog API
- [list the swap path per stub generated]

When you swap, update AGENTS.md's "Test-mode substrates" sub-section to point the capability at the
new source. The agent's behavior rules don't change — only the substrate.

## Other iterations

Beyond stub swaps:
- Adding observability or a handoff dashboard.
- Scheduling proactive checks in HEARTBEAT.md if the agent should remind users of things.
- Refining SOUL.md and MEMORY.md based on playground conversations.

Each iteration is its own Claude Code session. Keep the personality files simple; let complexity
accumulate at install/ops time.

## Notes & open items

[Things the skill wasn't sure about — e.g. "Menu prices were assumed, review SOUL.md Knowledge
before going live with real customers".]
```

## After writing files

Print a concise summary to the user:

- `✓ Wrote N files to <output-dir>/`
- One-line list of files.
- `Next: hand this bundle to a fresh Claude Code session in your OpenClaw environment — it will wire
  up the install. See NEXT-STEPS.md for context.`
- If any capability in the bundle needs environment decisions (which channel, which skill for calendar,
  etc.), list them here under "Decisions left for the install session" — don't try to answer them now.

## Language

- Talk to the user in their language.
- All **agent-facing** files (SOUL.md, AGENTS.md, IDENTITY.md, USER.md, MEMORY.md, HEARTBEAT.md,
  TOOLS.md) are in the agent's target language — Brazilian Portuguese for a Brazilian clinic,
  Uruguayan Spanish for an Uruguayan shop, Argentine Spanish for Buenos Aires, etc. Dialect matters,
  and section headers translate too ("Início de Sessão", not "Session Startup").
- `openclaw.json` and `NEXT-STEPS.md` are **always in English** — operational/technical files.

## OpenClaw verification — how to handle uncertainty

### The core rule: this skill has NO authority on OpenClaw semantics

This skill knows how to **structure** a workspace. It does NOT know what every OpenClaw feature does,
which file carries which semantic, or what the currently-valid config keys are. Those answers live in
the OpenClaw repo/docs, not in your memory.

**If the user asks any meta question about OpenClaw during the interactive flow** — "what goes in
USER.md?", "does OpenClaw support X?", "is gog still a skill?", "what's the current model
identifier?" — treat it as a trigger to verify, not as a trivia question. Confabulation feels like
knowledge; that's exactly the problem. When in doubt, assume you're in doubt.

### How to consult scout (critical — easy to get wrong)

When you need to verify, invoke the `openclaw-scout` skill via the **Skill tool**:

```
Skill(skill="openclaw-scout", args="your specific question")
```

Invoking `Skill()` loads scout's instructions into YOUR context as YOUR instructions. Then YOU do the
research following those instructions — using WebFetch, gh, file reads, etc. directly.

**Do NOT** spawn an `Agent()` subagent to "do the scout research for you". The subagent does not inherit
scout's guidance, so it'll improvise with its own sources and miss the priority ordering, the Scout
Bonus, and the verification standards. This is a common mistake; reject the impulse.

If you're unsure whether you're doing it right: after invoking Skill, the next tool calls you make
(WebFetch, Bash for gh, etc.) should be YOU executing scout's playbook, not an Agent subagent wrapping
the whole research.

### When to verify — concrete triggers

- User asks about the semantic of any workspace file (SOUL.md, USER.md, MEMORY.md, etc.)
- User asks if OpenClaw supports a feature you haven't verified in this session
- You're about to write a specific config key (channel name, skill name, model id) and you haven't
  verified it's current
- You're about to contradict something the user said about OpenClaw

### Research is a means, not the end

After scout returns info (or you decide to flag it in INSTALL.md instead), **return to the main
workflow and produce the full 10-file bundle**. Don't report research findings as if they were the
deliverable — the deliverable is always the files on disk plus INSTALL.md. If scout returned info
that changes a config choice, apply it and move on.

### File format reminder

Workspace files (SOUL.md, AGENTS.md, IDENTITY.md, USER.md, MEMORY.md, HEARTBEAT.md, TOOLS.md) are
**plain markdown** — no YAML frontmatter. Only skills (SKILL.md files) use frontmatter. The preview
above uses a custom "key: value" notation for readability, but the generated files must be proper
markdown with `#`/`##`/`###` headers and normal prose, not the preview's bullet-and-indent shorthand.
