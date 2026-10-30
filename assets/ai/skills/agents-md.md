---
name: agents-md
description:
  Use when writing or updating a project's AGENTS.md. Keeps it descriptive and
  low-churn, so it rarely goes stale.
---

# Writing a project AGENTS.md

A project `AGENTS.md` tells an agent how the repository is put together and how
to work in it. It is read at the start of every session, so every line has to
earn its place. The main goal is low churn: a good `AGENTS.md` is still true
after most changes.

## What belongs

Only what is very unlikely to change:

- What the project is, in a sentence or two.
- The structure, at the level of groups of things (directories and what lives in
  each), not a list of every file.
- Tooling, the default dev shell and the commands that run formatting, checks
  and builds.
- Workflows: how a change gets from edit to merge, and what CI runs.
- What is generated, and where the source of truth for it lives.
- Project-specific guidelines that an agent cannot infer from the code.

It describes and does not prescribe. A reader should be able to infer the
process for a task from it.

## What does not belong

- General language, framework or security advice. That is not specific to the
  repository and lives in my global file.
- Things that change often: version numbers, dependency lists, counts, dates,
  the names of every module or package, the current state of in-progress work.
- Anything the code already says clearly. Point at where to look instead of
  copying it.
- Secrets, personal details and anything about the job search.

## How to write it

1. Skim the metadata first: `README.md`, flake files, `Cargo.toml`,
   `package.json` and the like. Sample the tree. Then synthesize and do not
   transcribe.
2. Check every claim against the repository before writing it down. Do not
   describe what you assume is there.
3. Group, do not enumerate. Say "one file per machine under `machines/`" and not
   a list of machines. When naming examples, mark them as examples ("for
   example").
4. Prefer a short section with a pointer over a long section with a copy.
5. For each line, ask: if someone adds or removes a module next month, is this
   still true? If not, cut it or make it more general.
6. Keep it short. If it grows past a page or two, something in it belongs in
   `README.md` or a doc.

## Shape

A title, a one-paragraph summary, then sections like these, using only what
applies:

- `Structure`: directories and what lives in each.
- `Development`: entering the dev shell and the commands that matter.
- Generated files, if any, and where they come from.
- Anything unusual about how changes are reviewed or released.

## Keeping it fresh

When a change makes the `AGENTS.md` stale, update it in the same change. If you
notice an existing inconsistency, point it out and suggest a fix and do not fix
it silently.

If a project has none, say so and offer to write one together. Show a draft and
let me cut it down. I would rather trim a short one than review a long one.
