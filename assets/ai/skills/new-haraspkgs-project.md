---
name: new-haraspkgs-project
description:
  Use when starting a new project, repository or flake, or when adding Nix
  tooling to an existing one. Builds it on haraspkgs and routes everything
  through it. Not for projects that cannot use haraspkgs.
---

# New haraspkgs project

[haraspkgs](https://github.com/haras-unicorn/haraspkgs) is the shared Nix
library behind my repositories. It gives every project the same flake plumbing
and the same dev shell. This skill sets up a new project on it, so I do not have
to explain how it works every time.

## Go maximalist

If haraspkgs can do it, do it through haraspkgs. That covers the dev shell,
formatters, checks, language servers, the `dev` CLI, `.gitignore`,
`.gitattributes`, EditorConfig, the license, the code of conduct and GitHub
workflows.

- Do not hand-write a file the dev shell can generate.
- Do not add a second tool for something a haraspkgs module already covers.
- A hand-written file or a separate tool is the exception and needs a reason.

Some projects cannot use haraspkgs: a language ecosystem that insists on its own
tooling, or a repository someone else owns. When that happens, say so and ask.
Then still use the pieces that fit. Do not drop haraspkgs silently, and do not
half-adopt it without saying so.

## Before you start

Ask only what was not stated. Keep it to a few focused questions and lead with
your recommendation. Usually: what the project is, its languages, whether it
ships packages, which license, and whether it needs CI.

## Read, then write

The docs change between releases, so read them and do not write from memory.
Read the
[introduction](https://github.com/haras-unicorn/haraspkgs/blob/main/docs/introduction.md)
to get the idea, then the
[summary](https://github.com/haras-unicorn/haraspkgs/blob/main/docs/SUMMARY.md)
for the full list of pages. Pick the tutorials, guides and references that fit
the task, and look there before inventing anything.

## Example to copy from

[The haraspkgs dev shell](https://github.com/haras-unicorn/haraspkgs/blob/main/src/self/default.nix)
is the reference shape, and close to what most of my shells use: packages, git,
EditorConfig, languages, checks, formatters, license, CLI commands and
workflows, all as options. Copy the shape, then drop what the new project does
not need.

## Steps

1. `flake.nix`: a `nixpkgs` input, a `haraspkgs` input pinned to the latest
   release tag, and `haraspkgs.lib.makeFlake` over `./src`. Do not declare
   `flake-parts` or `import-tree`; haraspkgs provides them.

   ```nix
   outputs =
     { haraspkgs, ... }@inputs:
     haraspkgs.lib.makeFlake {
       inherit inputs;
       modules = [ ./src ];
     };
   ```

2. `src/`: every `.nix` file is a flake module. Start with `systems.nix` and a
   dev shell at `dev/shell.nix` that registers `self.devShells.default`.
3. `git add` the new files, then check through the `nix` MCP. Reference the
   flake as `git+file://<project root>`, which only sees tracked files.
4. Commit the generated files (`.gitignore`, `.gitattributes`, workflows,
   `LICENSE.md`). The dev module is their source of truth, so edit it and not
   the files.
5. Write the project's `AGENTS.md` with the `agents-md` skill, and keep
   `README.md` short.

Stop after steps 1 and 2 for review before filling in the rest of the dev shell.
