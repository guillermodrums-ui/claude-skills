# OpenClaw Workspace File Reference

Quick reference for what files an OpenClaw agent workspace expects. This skill generates the
**personality** files (plain markdown) plus a minimal `openclaw.json` entry and a `NEXT-STEPS.md`
handoff. Environment configuration (channels, plugins, skills, providers, CLI) is explicitly
out of scope — it belongs to a separate install session that verifies against live OpenClaw docs.

## Files the skill generates

| File | Purpose | Size guideline |
|---|---|---|
| `SOUL.md` | Personality, voice, expressions, boundaries, knowledge | 100–300 lines |
| `AGENTS.md` | Operating rules, capabilities, handoff, memory instructions, channel behavior | 80–200 lines |
| `IDENTITY.md` | Name, creature, vibe, emoji | ~5 lines |
| `USER.md` | Operator profile (the human the agent serves, when there's a single owner) | ~20–60 lines |
| `MEMORY.md` | Curated long-term memory: seeded business context + scaffolding for patterns/FAQs/rules | ~40–80 lines |
| `HEARTBEAT.md` | Periodic check tasks — empty = no heartbeat | 1–10 lines |
| `TOOLS.md` | Channel-formatting conventions + business quick references. No tech config. | 20–80 lines |
| `openclaw.json` | Minimal agent entry for `agents.list[]` — only `id` and `workspace` | ~5–10 lines |
| `NEXT-STEPS.md` | Tech-neutral install handoff: what's in the bundle + what the installer session must wire | ~30–50 lines |

## OpenClaw directory layout (for reference, not written by the skill)

When eventually installed, the workspace lives at `~/.openclaw/workspace-<slug>/` and the gateway
config at `~/.openclaw/openclaw.json`. This skill doesn't touch those — it just produces a bundle
for the installer session to place there.

## Key rules for each file

- **SOUL.md**: personality + voice. Behavioral effects only, no life stories. Describe how the agent
  should feel and sound.
- **AGENTS.md**: operational manual. Rules, memory instructions, channel behavior rules (in plain
  language — "WhatsApp messages stay short" not "dmPolicy: open"), handoff protocol. Multi-intent
  agents use sub-sections under Capabilities.
- **IDENTITY.md**: name, creature, vibe, emoji. Optional avatar.
- **USER.md**: operator profile when there's a clear owner (a personal assistant serves one human;
  a clinic bot serves the clinic/operator). For multi-tenant bots talking to many anonymous users,
  describe the **business operator**, not the end customer — individual customer profiles go to
  `memory/YYYY-MM-DD.md` at runtime.
- **MEMORY.md**: seeded with stable business context + empty scaffolding for Observed Patterns,
  Frequently Asked Questions, Learned Operational Rules. Agent (or operator) fills over time.
  Durable stuff only; efémera goes to `memory/YYYY-MM-DD.md`.
- **HEARTBEAT.md**: empty = no proactive checks. Customer-facing bots typically don't need one.
- **TOOLS.md**: channel formatting rules (no markdown tables on WhatsApp, etc.) + business-specific
  quick references. **No provider names, plugin identifiers, CLI commands, API endpoints.** Those
  are install-time concerns.
- **openclaw.json**: two fields only — `id` and `workspace`. Added under `agents.list[]` by the
  installer session, alongside whatever channel/skill/policy config the installer verifies against
  the current OpenClaw schema.
- **NEXT-STEPS.md**: tech-neutral. Lists what's in the bundle and gestures at the install steps
  without naming CLI commands or config keys. The installer session uses live docs or `/openclaw-scout`
  to fill in the specifics.

## Handoff behavior (describe in AGENTS.md)

OpenClaw's native handoff is "silent mode": the agent stops replying and stays passive until
reactivated by another agent, the operator, a timeout, or a topic-change detector. Describe this
as the agent's **behavior** (what it does when triggered), not as a mechanism (no tags, no codes,
no CLI). The installer session wires up the reactivation surface.

## Anti-hallucination

Lives in AGENTS.md Red Lines, phrased as a behavior rule: "only confirm appointments that appear in
the calendar of available slots — never invent a time". The agent's source of truth stays abstract;
the actual storage (file, database, API) is wired at install time.

## What belongs to the installer session (out of scope for this skill)

- Channel config keys (`dmPolicy`, `groupPolicy`, provider names)
- Plugin identifiers (Baileys, grammY, etc.)
- Skill installations (`gog`, `session-logs`, `memory-wiki`, etc.)
- Model identifiers (`google/gemini-2.5-flash`, `anthropic/claude-*`)
- CLI commands (`openclaw gateway`, `openclaw channels login`, `openclaw skills install ...`)
- Integration stubs / real integrations (calendar files, lead DBs, catalog APIs)
- Authentication flows (QR pairing, OAuth, bot tokens)

All of the above change between OpenClaw releases. The install session verifies current names and
schema against live docs — it does not guess from memory.
