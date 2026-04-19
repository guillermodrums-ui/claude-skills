---
name: create-openclaw-agent
description: >
  Bootstrap a complete OpenClaw agent workspace (SOUL.md, AGENTS.md, IDENTITY.md, USER.md, MEMORY.md,
  HEARTBEAT.md, TOOLS.md, openclaw.json snippet, plus INSTALL.md) from an interview or an input document.
  The skill writes files to a LOCAL directory — it never touches the user's OpenClaw installation. Installation
  happens separately via the generated INSTALL.md commands. INVOKE THIS SKILL when: the user wants to create
  a new OpenClaw agent, scaffold a workspace, convert a business description or brand guide (.docx/.pdf/.md/.txt,
  including existing system prompts / config.yaml) into an agent, or says /create-openclaw-agent. Also invoke
  when the user mentions "set up a new bot", "create a chatbot for [business]", "make an agent for [client]",
  or any variation of wanting to scaffold a new OpenClaw agent from scratch — even if they don't mention OpenClaw
  by name, as long as context suggests they're working within the OpenClaw ecosystem.
---

# Create OpenClaw Agent

Your job is to produce a ready-to-install OpenClaw agent workspace — as a pile of files in a local directory —
based on information you gather from the user (interview) or extract from a document they provide. You do NOT
install the agent into the user's OpenClaw environment. You emit files + an `INSTALL.md` that tells them (or
another Claude Code session) exactly how to install.

This separation matters: the user may be on a different machine than where OpenClaw runs, may want to review
the files before installing, or may want to version-control the workspace in a repo.

## Two Input Modes

### Mode 1 — Interview (no argument)

`/create-openclaw-agent` with no file path → run a guided conversation. Ask about one category at a time in
natural style, not a rigid form. Adapt follow-ups to the business type (a dental clinic needs different
questions than a supplement shop).

### Mode 2 — From a document or text file

`/create-openclaw-agent <path>` → read the file first, extract what you can, THEN ask only about what's
missing or ambiguous. Supported inputs:

- `.docx` — use `python-docx` (`from docx import Document; [p.text for p in Document(path).paragraphs]`)
- `.pdf` — use the Read tool (it supports PDFs)
- `.md` / `.txt` / `.yaml` / `.yml` / `.py` — read as text

Existing system prompts (e.g. a `config.yaml` with topic-routed prompts, or a Python file with a
`SYSTEM_PROMPT = "..."` constant) are valid input. Parse them as text, extract the agent's personality,
rules, and behaviors, and reshape them into the 7 categories below. The output is still a fresh OpenClaw
workspace, not a mechanical port.

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

### 4. CHANNELS → openclaw.json, TOOLS.md, AGENTS.md
WhatsApp / Telegram / Discord / web / other. For each:
- dmPolicy (open / pairing / allowlist)
- Group behavior (ignore / respond-when-mentioned / always-respond)
- Channel-specific formatting (no markdown tables on WhatsApp, etc.)
- **Multimedia**: does the channel carry audio, images, video, documents? How should the agent handle
  them? (audio transcription prefixed with a marker, image captions surfaced, attachments stored, etc.)
  Ask explicitly — users often forget to mention it and the agent ends up silent on audios.

### 5. CAPABILITIES & TOOLS → AGENTS.md, TOOLS.md, openclaw.json

What the agent can DO. This is the richest category — explore it carefully.

**Basic capabilities to ask about:**
- Answer FAQs / provide information
- Schedule appointments (→ `gog` skill for Google Calendar)
- Process orders / recommend products
- Collect intake data
- Send reminders
- Handoff to human operator

**External tools and data sources — watch for these signals in the user's answers:**

- "it connects to…", "we have an API…", "the catalog is at…"
- "pulls from…", "syncs with…", "looks up…"
- Mentions of Google Calendar, Sheets, Drive, a CRM, an internal database

When you detect an external tool or data source, dig in:
1. What's the URL / endpoint?
2. Is there documentation? (file path, URL, or OpenAPI spec)
3. How does the agent use it — direct HTTP calls at runtime, or is data pre-loaded into RAG and synced?
4. What specifically does the agent need to do with it?
5. Auth: API key, OAuth, none?

### Test-mode first — the default philosophy

**This skill's job is to produce a workspace that runs AS-IS in test mode, with zero external
dependencies.** Real integrations (OAuth calendars, live APIs, vector stores) are a later iteration,
not part of the default bundle. The end user will connect them in a follow-up session once they've seen
the agent respond coherently in the playground.

This mirrors `workspace-clinicaejemplo` in OpenClaw's own tree: the bot reads/writes `agenda.md` as a
local mock for Google Calendar. Real `gog` gets wired later.

### Pattern map — prefer the test-mode column

For every integration need the user mentions (calendar, catalog, DB, FAQ, lead history), pick a
test-mode stub for the default bundle. Document the real integration only in INSTALL.md "Next steps".

| Need | Test-mode stub (default bundle) | Real integration (INSTALL.md "Next steps") |
|---|---|---|
| Calendar / scheduling | `agenda.md` — markdown table with dates/slots/status the agent edits in place | `gog` skill (Google Workspace OAuth) |
| Product or service catalog | `products.md` — list with name/price/description | Live HTTP API called from TOOLS.md |
| FAQ / canned answers | `FAQ.md` (or embed in SOUL.md Knowledge if small) | Pre-synced RAG / vector store |
| Lead history / audit log | `leads.sqlite` if structured queries needed, else `leads.md` | CRM integration, external DB |
| Known OpenClaw skill at test time | Install only if the skill runs offline (e.g. `session-logs`, `canvas`) | `gog`, `notion`, `slack` etc. → Next steps |

### .md vs sqlite for local stubs — how to pick

- **Markdown (.md)** when the data is human-readable, small (<~100 rows), and the agent mostly READS + occasionally
  appends. Example: `agenda.md` with 7 days × 8 slots. Format as a structured table with unique row identifiers
  (`| seg 14/04 | 09:00 | ... |`) so the agent can do targeted edits without ambiguity.
- **SQLite (.sqlite)** when you need structured queries, larger volume, or the agent writes frequently.
  Example: `leads.sqlite` with `leads(phone, name, clinic_type, first_contact_at, status)`. Include a
  `leads.schema.sql` in the workspace as a reference for what the agent can query.

Default to .md unless the user explicitly asks for sqlite — markdown is auditable, diff-friendly, and the
operator can edit it manually while the bot is running.

### Anti-hallucination

Regardless of where the data lives, if the agent must only confirm info that's present in the source,
encode the rule in AGENTS.md Red Lines phrased around the actual source (`agenda.md`, `products.md`, the
API response, SOUL.md Knowledge) — not around a pattern name.

**Anti-hallucination** is a separate concern — applies regardless of where data lives. If the agent must
only confirm info that's present somewhere (RAG, API response, SOUL.md), encode that as a rule in AGENTS.md
Red Lines. Don't tie the rule to a specific data-access pattern.

Different runtimes do it differently, so ask:

1. What triggers a handoff? (unknown topic, user asks for human, specific keywords, complex request)
2. What's the handoff mechanism? Common options:
   - **OpenClaw-native "silent mode"**: the agent stops replying and waits for reactivation by another
     agent, the operator, a timeout, or a topic-change detector. This is OpenClaw's default handoff
     primitive — document the trigger conditions in AGENTS.md and flag in INSTALL.md that the runtime
     wiring (who/what reactivates the agent) is an install-time concern.
   - **Tail-tag** (e.g. a string like `[HANDOFF]` at the end of the response that middleware strips and
     uses to route): legacy pattern from some Python-based agents. Only use it if the end user confirms
     their runtime parses such a tag. Don't assume it's an OpenClaw convention — it isn't.
   - **Tool/skill call**: a dedicated `handoff_to_human` skill the agent invokes.
3. Where does the operator see the escalation? (another channel, a dashboard, a shared inbox)

Document the handoff mechanism the user describes in AGENTS.md under a Handoff Protocol section.
Don't invent a mechanism; if the user doesn't specify one, default to OpenClaw-native silent mode
and flag it in INSTALL.md "Notes & open items" as needing runtime confirmation.

**Multi-intent behavior.** Some agents behave differently across different topics (a supplement shop has
different rules for "product info" vs. "pharmacological dosing" vs. "checkout"). Don't replicate a routing
layer — these are behavior rules. Capture them in AGENTS.md as sections under Capabilities or as distinct
rule clusters. Example structure:

```
## Capabilities

### Product information
[rules for this intent]

### Dosing questions
[rules for this intent — maybe stricter than product info]

### Purchase intent
[rules for closing, handoff triggers]
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
  Capabilities: [bulleted, with sub-headings per intent if multi-intent]
  External tools: [catalog API at X / Google Calendar via gog / etc.]
  Red lines: [absolute rules]
  Handoff triggers: [when + how]
  Channel rules: [formatting per channel]

--- IDENTITY.md ---
  Name: [agent name]
  Creature: [AI assistant type]
  Vibe: [few words]
  Emoji: [emoji]

--- USER.md ---  [template, filled at runtime]
--- MEMORY.md --- [empty template]
--- HEARTBEAT.md --- [empty, or periodic checks]
--- TOOLS.md ---
  Channel formatting: [rules]
  External data: [API endpoint / RAG source / embedded in SOUL — whichever applies]
  Handoff mechanism: [silent-mode default / tail-tag if user confirmed it / dedicated skill]

--- openclaw.json (merge snippet) ---
  Channels: [which channels + dmPolicy]
  Model: [suggested LLM]
  Skills: [to install]

--- INSTALL.md (post-generation) ---
  Contains: copy-paste commands to install this workspace into the user's OpenClaw env

--- Output directory ---
  Path: [resolved path]
  [WARNING if path exists and is non-empty]

=== END PREVIEW ===
```

After showing: "Does this look right? Want to change anything before I write the files?"

## File patterns

Follow these patterns. All content in the agent's target language — **including section headers** — except
`openclaw.json` and `INSTALL.md`, which are always in English (they're technical/operational, not
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

```markdown
# TOOLS.md — Local Configuration

## Channel Formatting
### WhatsApp
- No markdown tables — bullet lists
- Short messages (1–3 paragraphs)
- **bold** for emphasis, not headers
- Emojis with moderation

## External Data Sources
[Pick whichever applies:
 - Direct HTTP API called at runtime: URL, endpoints, docs reference, auth approach, intended use.
 - Pre-synced RAG / vector store: source URL, sync pipeline, what's indexed, what isn't, refresh cadence.
 - Embedded in SOUL.md: no external source; state that the data is static and lives in the workspace.
 Document the "source of truth" clearly — downstream rules in AGENTS.md reference this.]

## Quick References
[Business-specific lookup tables: payment methods, shipping options, discount tiers, etc.]
```

### openclaw.json (merge snippet)

This is a **fragment** the user will merge into their real `~/.openclaw/openclaw.json`. Use JSON5 (comments
ok). Minimal — only sections relevant to this agent.

```json5
{
  // [Agent Name] — generated by create-openclaw-agent
  // Merge this into your ~/.openclaw/openclaw.json — do not replace the whole file.
  identity: {
    name: "[Agent Name]",
    theme: "[one-line theme]",
    emoji: "[emoji]"
  },
  agent: {
    workspace: "~/.openclaw/workspace-[slug]",  // adjust if your layout differs
    model: {
      primary: "google/gemini-2.5-flash"  // cost-effective default; change to taste
    }
  },
  channels: {
    // Only include channels the agent uses
    whatsapp: { enabled: true, dmPolicy: "open" }
  },
  defaults: {
    heartbeat: { showOk: false, showAlerts: true }
  }
}
```

### INSTALL.md (always generated last)

This file is **for the human installing the bundle** (the end user, or another Claude Code session) —
it does NOT go into the agent's workspace. It's the recipe to take the generated files from the local
output directory and install them into an OpenClaw environment. Always written in English (operational
content, not customer-facing).

Structure — two parts:

**Part 1 — Install as-is (test mode).** The default bundle is self-contained: local stub files replace
every external integration. These steps get the agent running in the playground in ~5 minutes with
zero upstream dependencies. Contents:

1. **What this bundle is** (2-line summary, including the test-mode stubs used — e.g. "uses `agenda.md`
   as a Google Calendar mock").
2. **Prerequisites** — OpenClaw installed; no external services required for test mode.
3. **Install steps** (copy-paste ready):
   - Create the workspace: `openclaw agents add <slug>` or `mkdir -p ~/.openclaw/workspace-<slug>`
   - Copy all `*.md` files + any stub files (`agenda.md`, `products.md`, `leads.sqlite`, etc.)
   - Merge the `openclaw.json` snippet — identity override for single-agent, else under `agents.list[]`
4. **Channel setup (test mode)** — for WhatsApp/Telegram/web, just enough to get messages flowing.
5. **Verification** — `openclaw agents list`, playground smoke test with concrete suggested prompts.
6. **Notes & open items** — things the skill wasn't sure about and the user should review before real use.

**Part 2 — Next iterations (real integrations).** Lists the integrations that are currently stubbed
and what to do when the user wants to wire them up for real. Each entry has the trigger, the skill/API
to install, and what file(s) in the workspace to update. Example entries:

- **Calendar (currently stubbed via `agenda.md`)** → when ready to use a real calendar:
  `openclaw skill install gog`, follow OAuth setup, update TOOLS.md and AGENTS.md to read/write via
  `gog` CLI instead of editing `agenda.md`.
- **Catalog (currently in `products.md`)** → when ready: point at the live API, update TOOLS.md with
  endpoint + auth, remove `products.md` or keep as local cache.
- **Lead history (currently `leads.sqlite`)** → when ready: migrate to a CRM.

Keep Part 2 short and actionable. It's a hand-off, not a spec — Claude Code in a follow-up session
will do the actual wiring.

Template:

```markdown
# INSTALL.md — [Agent Name]

Generated by create-openclaw-agent on [date]. Target: install as a new OpenClaw agent named `[slug]`.

## Prerequisites
- OpenClaw installed and running (`openclaw --version`)
- [Any skill prerequisites, e.g. `openclaw skill install gog`]

## Install

1. **Create the workspace directory**
   ```bash
   mkdir -p ~/.openclaw/workspace-[slug]
   ```
   (Or use `openclaw agents add [slug]` if you prefer the wizard — it creates workspace + state dir + session store.)

2. **Copy the generated files**
   ```bash
   cp [output-dir]/SOUL.md ~/.openclaw/workspace-[slug]/
   cp [output-dir]/AGENTS.md ~/.openclaw/workspace-[slug]/
   cp [output-dir]/IDENTITY.md ~/.openclaw/workspace-[slug]/
   cp [output-dir]/USER.md ~/.openclaw/workspace-[slug]/
   cp [output-dir]/MEMORY.md ~/.openclaw/workspace-[slug]/
   cp [output-dir]/HEARTBEAT.md ~/.openclaw/workspace-[slug]/
   cp [output-dir]/TOOLS.md ~/.openclaw/workspace-[slug]/
   ```

3. **Merge `openclaw.json` snippet** into `~/.openclaw/openclaw.json`
   - For single-agent setups: copy the `identity`, `agent`, `channels`, `defaults` keys from the snippet.
   - For multi-agent setups: add an entry under `agents.list[]` with `id: "[slug]"` and `workspace:
     "~/.openclaw/workspace-[slug]"`, and add the channel binding under `bindings`.

4. **Channel setup**
   [Per-channel steps based on what was configured. Examples:]
   - **WhatsApp (Baileys):** on first start, scan the QR code shown in the gateway logs.
   - **Telegram:** create a bot with @BotFather, put the token in `channels.telegram.botToken` in openclaw.json.

5. **Skills to install** (if any)
   ```bash
   openclaw skill install gog    # Google Calendar — only if scheduling is needed
   ```

6. **Start the gateway**
   ```bash
   openclaw start
   ```

## Verify

```bash
openclaw agents list
```

You should see `[slug]` in the list. Send a test message through the configured channel and check the
gateway logs.

## Notes & open items

[Things the skill wasn't sure about — e.g. "Exact menu prices were assumed, review SOUL.md Knowledge section",
"Custom catalog API: you'll need to create a skill or use a plugin to connect — URL is in TOOLS.md"]
```

## After writing files

Once all files are written to the output directory, print a concise summary:

- `✓ Wrote 9 files to <output-dir>/`
- One-line list of files
- `Next step: follow INSTALL.md to install into your OpenClaw environment.`
- If any skills need to be installed, surface that command explicitly here too.

## Language

- Talk to the user in their language.
- All **agent-facing** file contents (SOUL.md, AGENTS.md, IDENTITY.md, USER.md, MEMORY.md, HEARTBEAT.md,
  TOOLS.md) are in the agent's target language — Brazilian Portuguese for a Brazilian clinic, Uruguayan
  Spanish for an Uruguayan shop, etc. Dialect matters.
- `openclaw.json` and `INSTALL.md` are **always in English** — they are technical/operational files, not
  customer-facing.

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
