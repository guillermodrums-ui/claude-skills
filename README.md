# claude-skills

A collection of [Claude Code](https://docs.claude.com/en/docs/claude-code) skills I've built and use day-to-day. Shared in case they're useful to someone else.

## What are Claude Code skills?

Skills are reusable instructions that extend Claude Code. Each skill is a directory under `~/.claude/skills/` containing a `SKILL.md` (with frontmatter describing when to invoke it) plus optional supporting files. Claude Code loads them at startup and invokes them automatically when the user's request matches, or explicitly when the user types `/<skill-name>`.

Official docs: <https://docs.claude.com/en/docs/claude-code/skills>

## Available skills

| Skill | What it does |
|---|---|
| [`create-openclaw-agent`](skills/create-openclaw-agent/) | Scaffolds a complete [OpenClaw](https://github.com/openclaw/openclaw) agent workspace (SOUL.md, AGENTS.md, IDENTITY.md, HEARTBEAT.md, etc.) from an interview or an input document (.docx/.pdf/.md/.txt/.yaml). Writes files locally; installation into OpenClaw happens separately via the generated `INSTALL.md`. |

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
