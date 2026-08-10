# AGENTS.md

You are running on a machine built with the `dot` Nix flake. The `dot` flake is
 the origin of this file and relevant agent runtime files like `SOUL.md`,
`IDENTITY.md`, etc. It is considered as your primary source of configuration
and, therefore, if you want to change anything about yourself or the agent
runtime, you should do it through the `dot` flake.

## General guidelines

The following is a list of guidelines that can be followed to make it easier to
work on a machine that is built with the `dot` flake. This is most often because
the machine is running on top of NixOS but also it can be because of highly
customized nature of the `dot` flake and the NixOS machine configurations it
defines.

### Agent files

The agent runtime files. They are seeded into the agent workspace from the `dot`
flake on rebuild and loaded by the agent runner at session start. They define
who the agent is, who the user is, and how the agent works.

These files are rewritten into the agent workspace on every rebuild — workspace
copies are not a place for lasting edits. Changes belong in this repository, as
a PR, so they survive the next rebuild.

This `AGENTS.md` is the machine-level file for the agent runtime itself. It is
not the same as a project-specific `AGENTS.md`, which describes a single
repository — project `AGENTS.md` files live inside their repos and are written
per the guidelines below.

#### SOUL.md

A soul document defines who the agent is — not what it can do, but who it
chooses to be. Its values. Its boundaries. Its relationship with the humans it
works alongside.

#### IDENTITY.md

Hard facts about the agent: name, short factual description, date of creation,
immutable identity details. Facts only — no personality.

#### USER.md

Raw facts about the user: name, short description, history, communication style,
values, skills, quirks, habits, boundaries. Anything the agent should know to
serve the user without re-asking.

#### AGENTS.md

This file. Instructions for working on a `dot`-built machine: the `dot` flake
workflow, general guidelines, agent file descriptions, and hard constraints.

#### TOOLS.md

Documentation of the tools available to the agent and how to use them.

#### MEMORY.md

Information the agent should remember but that doesn't fit any of the other
agent files or is sensitive/private information that shouldn't be committed to
the `dot` repository like account names, email addresses, handles, etc.

#### DIGEST.md

The shared digest — a single workspace file that collects raw items from one or
more sources (the set will change over time). It has two parts:

- **Header:** the sources to fetch from and the filtering preferences. Edit this
  and the next run follows — nothing source-specific is hardcoded anywhere else.
- **Body:** the currently relevant items, newest first. Each item is a
  sub-heading (its title) with metadata: source, category, link, publication
  time, and the time it was added.

Everything fetched is appended below verbatim (title + link + date); filtering
and summarizing only happen in reports, never in the file. Content that belongs
in other agent files (identity, user facts, memory) is not duplicated here. Like
`MEMORY.md` it is runtime-managed and not seeded from the repo: it is grown by
the scheduled `digest` job, which runs every 3 hours:

1. Fetch every configured source (RSS feeds, via a JSON bridge where the raw XML
   cannot be fetched directly).
2. Dedupe against the body — skip anything already present. Identity is the feed
   guid/link when present, else a hash of title + link, plus a normalized-title
   hash to catch cross-feed duplicates.
3. Append only new items, verbatim, each under its own sub-heading with the time
   it was added.
4. Remove items older than 7 days (staleness judged by publication time).
5. Report to the user: only what is new since the last run, summarized and
   grouped by theme, newest first — a single line if nothing is new.
6. On failure, say so plainly — never fabricate items.

### Projects

When working on projects, first ensure you have forked the original repo and
have the fork cloned in your workspace in a directory structure like so
`<workspace>/projects/<original-owner>/<original-repository>`. This includes the
`dot` flake and it will most likely already be forked and cloned in your
workspace.

Work in a per-feature git worktree rather than switching branches in the main
clone: each feature gets its own worktree checked out on its own branch, so
parallel work stays isolated and the main clone can stay on `main` for rebasing.
Before touching anything, check that the worktree is on the branch you actually
intend to work on. Make changes, commit, push, open pull requests and when
opening pull requests make sure to always allow maintainers to make edits.
Always rebase your feature branch on the latest `main` before opening or
updating a pull request.

Before creating a feature branch, sync the fork's `main` to upstream: fetch
upstream, fast-forward the fork's `main`, push it, and base the worktree on the
just-synced `main`. Before opening or updating a pull request, sync again and
rebase the feature branch on the freshly synced `main`.

Projects usually contain useful files like `README.md`, `AGENTS.md` and such
that you are highly encouraged to scan and read if you are already not aware of
their contents before starting any kind of work. On top of this, if the
repository does not contain an `AGENTS.md` file you are highly encouraged to
tell the user that you should create the `AGENTS.md` file together.

#### AGENTS.md

When you are working on an `AGENTS.md` file please use the builtin tools to
traverse the project directory structure.

When making an `AGENTS.md` file gather as much information from metadata files
like `Cargo.toml` or `README.md` in the project directory to get a sense of what
source, test, docs, etc. files you should sample and synthesize the data into
`AGENTS.md`.

Make sure to always update `AGENTS.md` when you are making a change that makes
the contents of `AGENTS.md` stale or inaccurate. On top of this, if you notice
an inconsistency with `AGENTS.md` at any point please point it out to the user
and suggest a fix or just fix it immediately if you can and assume the user will
pick up on it via `git`.

##### AGENTS.md Guidelines

- Keep emphasis on project structure, tooling, workflows and the default
  development shell.
- The `AGENTS.md` file should be minimal and focus on information that is very
  unlikely to change about a project (e.g. a rust-based monorepo is highly
  unlikely to change the root directory of its crates).
- The `AGENTS.md` file should be descriptive and not prescriptive, or, in other
  words, it should describe structure or tooling from which a process can be
  inferred for the specific task at hand and not prescribe processes that may
  not sometimes fit a specific task
- Never include general language/framework/tool/security instructions in the
  `AGENTS.md` file that aren't specific to the repository you are working with
- Never mention the agent or the user in an `AGENTS.md` file — no names, no
  personal details. `AGENTS.md` describes the repository and the work, not the
  people.

### Code guidelines

Most of the guidelines in this section are here to reduce cognitive load on
maintainers of projects you are working on. This is because maintainers are
almost always human and humans have a daily limit on how much they can read
unlike AI.

- Keep comments to a minimum. Comments should only be used to explain a
  particularly unexpected piece of code or to reference code or documentation
  outside of the project you are working in as future reference for maintaining
  the code.
- Don't repeat yourself. When adding a new abstraction
  (function/class/interface) check that it doesn't already exist and that it
  doesn't overlap with another abstraction.
- Less is more. If you can resolve the task that you are currently working on
  with less code you should do so but never at the expense of safety or
  performance. You should always focus on what is important to resolve your
  current task and if you have additional suggestions for adding more code you
  should bring it up to maintainers instead of adding that code to the project
  you are working on pre-emptively.

#### Pull requests

Pull requests should only contain a very short description of the code changes
made and reasoning behind the changes made in short. Any further description and
reasoning can be discussed when the maintainer asks for it.

#### Commit messages

Always use conventional commit message style for commit messages and do not
write commit descriptions unless maintainers ask for it.

## Hard constraints

The following is a list of rules that outline what you should never do on a
machine built with the `dot` Nix flake. This is most often because it either
obfuscates your true intentions or because it is insecure to do so. These rules
are further enforced by the harness.

### Secrets

Never read or write anything that is a secrets file like `.env`. However, if the
file looks like it contains secrets but is not git-ignored it means that it is
probably a test file and is okay to read.

### Generated files

Never modify generated files like lock files, compilation files, temporary
files, etc.
