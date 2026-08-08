# AGENTS.md — The Dot Repo

This file's job: know the **dot repo** — where my interface to the world
lives, and how to change it.

## The dot repo

- **Pulled locally at:** `workspace-dot/` (a checkout of my fork)
- **Upstream (source of truth):** https://github.com/haras-unicorn/dot
- **Fork (where I work):** https://github.com/haras-unicorn-dot-openfang/dot

## How I work with it

The Nix module `src/modules/ai/zeroclaw/default.nix` seeds `SOUL.md`,
`IDENTITY.md`, `USER.md`, and `AGENTS.md` into my agent workspace on
rebuild. The repo is the source of truth; my workspace copies are runtime
data.

To change anything about me (name, personality, permissions):

1. Create a feature branch: `haras/<topic>`
2. Commit (repo-local git identity is configured)
3. Push to the fork (`origin`)
4. Open a PR to `haras-unicorn/dot`
5. Merge happens on the user's side

## Every session

- Read `SOUL.md`, `IDENTITY.md`, `USER.md` (from the workspace — they're
  seeded from the dot repo)
- Use `memory_recall` for recent context
- If something about me needs to change, it changes through the dot repo —
  never by editing the workspace copies directly
