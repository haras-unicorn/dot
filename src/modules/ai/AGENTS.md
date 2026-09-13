# AGENTS.md

You are running on a machine built with the `dot` Nix flake.

## Working with the user

- Deliberate before writing. Ask about design goals that were not stated.
- Warn about volume and burnout. Sometimes refuse to go faster.
- Make the user read and approve code before starting the next thing.
- Prioritize readability and maintainability over speed.
- Stop to record decisions that will matter later.
- Keep project-specific guidelines in project `AGENTS.md` files and shared
  guidelines in this file.
- Keep replies and changes small.

## General guidelines

The following is a list of guidelines that can be followed to make it easier to
work on a machine that is built with the `dot` flake. This is most often because
the machine is running on top of NixOS but also it can be because of highly
customized nature of the `dot` flake and the NixOS machine configurations it
defines.

### Projects

Almost always, you will be launched in a project directory that is a git
repository containing useful files like `README.md`, `AGENTS.md` and such that
you are highly encouraged to scan and read if you are already not aware of their
contents before starting any kind of work. On top of this, if you are launched
in a directory without an `AGENTS.md` file you are highly encouraged to tell the
user that you should create the `AGENTS.md` file together.

### AGENTS.md

When you are working on an `AGENTS.md` file please use the filesystem MCP tools
to traverse the project directory structure.

When making an `AGENTS.md` file gather as much information from metadata files
like `Cargo.toml` or `README.md` in the project directory to get a sense of what
source, test, docs, etc. files you should sample and synthesize the data into
`AGENTS.md`.

Make sure to always update `AGENTS.md` when you are making a change that makes
the contents of `AGENTS.md` stale or inaccurate. On top of this, if you notice
an inconsistency with `AGENTS.md` at any point please point it out to the user
and suggest a fix or just fix it immediately if you can and assume the user will
pick up on it via `git`.

#### AGENTS.md Guidelines

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

### Tools

The following MCP servers are available:

- `git` for repository operations. It can read and write the working tree, but
  pushing, tagging, and remote changes are denied.
- `filesystem` for reading and editing files under the directory where the AI
  tool was started.
- `nix` for building, checking, and running nix commands inside a sandbox.

`webfetch` and `websearch` are the only built-in tools. Use them for web access.
All other built-in tools are hidden.

Use the filesystem MCP tools instead of shell commands such as `cat`, `grep`, or
`sed`.

### Development shells

Most often, you will be launched in a directory that is a Nix flake. Use the nix
MCP `nix_develop` tool to run commands inside the project's development shell.
For example, pass `flake = "path:."`, the command you need, and the project root
as the working directory. If a project has no flake, say so instead of running
commands on the host.

## Hard constraints

The following is a list of rules that outline what you should never do on a
machine built with the `dot` Nix flake. This is most often because it either
obfuscates your true intentions or because it is insecure to do so. These rules
are further enforced by the harness.

### Sandbox

The MCP servers are scoped to the directory where the AI tool was started. Treat
that directory (`$PWD`) as the project root: read and write files through the
filesystem MCP, run git through the git MCP, and run nix commands through the
nix MCP. Do not try to reach outside the project root. Ask the user before
reading or writing anything in the home directory.

### Temporary directory

Never read, write or execute anything in the `/tmp` directory.

### Secrets

Never read or write anything that is a secrets file like `.env`. However, if the
file looks like it contains secrets but is not git-ignored it means that it is
probably a test file and is okay to read.

### Generated files

Never modify generated files like lock files, compilation files, temporary
files, etc.

### The Nix root directory

Never read, write or execute anything inside the nix root directory (`/nix`).
This includes the following:

- Manually reading, writing or executing anything inside the nix root directory
  with commands such as `rm`, `cp`, `mv`, etc.
- Using any command that directly references a path from the nix root directory.

### Execution

Do not run commands on the host. Use the nix MCP for nix commands and the
filesystem and git MCP servers for file and repository work. The nix MCP runs
commands inside a sandbox with the project root bound and network disabled.

## References

- [dot](https://github.com/haras-unicorn/dot) flake URL.
