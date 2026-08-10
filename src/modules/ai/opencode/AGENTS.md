# AGENTS.md

You are running on a machine built with the `dot` Nix flake.

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

### Development shells

Most often, you will be launched in a directory that is a Nix flake and when
this is the case you will almost certainly be launched inside of the default
development shell of that Nix flake, so you should just assume you are working
inside of the current repositories' default development shell if it contains a
`flake.nix` file. If, for whatever reason, you are not aware of all the tools at
your disposal inside of the default development shell, you should introduce
yourself to whatever tools the default development shell provides before doing
any kind of work.

## Hard constraints

The following is a list of rules that outline what you should never do on a
machine built with the `dot` Nix flake. This is most often because it either
obfuscates your true intentions or because it is insecure to do so. These rules
are further enforced by the harness.

### Sandbox

Never read or write anything outside of the following:

- The project root directory that you are currently running inside of.
- You are allowed to ask to write or read from the current user's home
  directory.

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

You are disallowed from executing any command that does not begin with `dev`,
`just` or `make`. Never try to use the actual `grep`, `rm` or `cp` commands
instead of the builtin tools.
