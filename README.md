# claude-skills

A collection of [Claude Code](https://docs.claude.com/en/docs/claude-code) skills I've built and use day-to-day. Shared in case they're useful to someone else.

## What are Claude Code skills?

Skills are reusable instructions that extend Claude Code. Each skill is a directory under `~/.claude/skills/` containing a `SKILL.md` (with frontmatter describing when to invoke it) plus optional supporting files. Claude Code loads them at startup and invokes them automatically when the user's request matches, or explicitly when the user types `/<skill-name>`.

Official docs: <https://docs.claude.com/en/docs/claude-code/skills>

## Available skills

| Skill | What it does |
|---|---|
| [`create-openclaw-agent`](skills/create-openclaw-agent/) | Bootstraps the **personality** of an [OpenClaw](https://github.com/openclaw/openclaw) agent — SOUL.md, AGENTS.md, IDENTITY.md, USER.md, MEMORY.md, HEARTBEAT.md, TOOLS.md, a minimal `openclaw.json`, and a `NEXT-STEPS.md` handoff — from an interview or a document (.docx/.pdf/.md/.txt/.yaml). Intentionally tech-neutral: does NOT configure channels, install plugins, or prescribe CLI commands — environment wiring happens in a follow-up session against live OpenClaw docs. |
| [`create-openclaw-real-estate-agent`](skills/create-openclaw-real-estate-agent/) | Real-estate–specialized variant of the generic skill. Drives an 8-category interview tailored to the industry: property catalog management, client indagation flow (alquiler vs. compra first), seller mode, lead database, operator secretary mode, learning system, and handoff triggers. Emits the 7 canonical files **plus** `propiedades.md` (catalog stub), `leads.sqlite` + `leads.schema.sql` (structured lead DB), and `contexto-operador.md` (campaigns + operator instructions). Same tech-neutral split — install session wires channels and plugins. |

## Install

One-shot install of a specific skill:

```bash
curl -sSL https://raw.githubusercontent.com/guillermodrums-ui/claude-skills/main/install.sh | bash -s create-openclaw-agent
```

List available skills:

```bash
curl -sSL https://raw.githubusercontent.com/guillermodrums-ui/claude-skills/main/install.sh | bash
```

Install everything:

```bash
curl -sSL https://raw.githubusercontent.com/guillermodrums-ui/claude-skills/main/install.sh | bash -s -- --all
```

The installer downloads a tarball of `main`, copies the selected skill(s) into `~/.claude/skills/`, and overwrites any existing copy. Restart Claude Code after installing so it picks up the new skill.

### Manual install (if you prefer)

```bash
git clone https://github.com/guillermodrums-ui/claude-skills.git
cp -r claude-skills/skills/create-openclaw-agent ~/.claude/skills/
```

Or symlink, so `git pull` updates the skill in place:

```bash
git clone https://github.com/guillermodrums-ui/claude-skills.git
ln -sf "$(pwd)/claude-skills/skills/create-openclaw-agent" ~/.claude/skills/create-openclaw-agent
```

## Updating

Re-run the same install command — the installer replaces the existing copy.

## Uninstall

```bash
rm -rf ~/.claude/skills/<skill-name>
```

## Contributing / issues

If you find a bug or want to suggest an improvement, open an issue. PRs welcome.

## License

MIT — see [LICENSE](LICENSE).
