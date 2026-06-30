# Dot Nix Machine Context

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

When you are working on an `AGENTS.md` file please use the `tree` and `list`
commands to traverse the project directory structure. Make sure to always pipe
them into the `head` command to ensure that the output is limited unless the
user asks not to do that.

When making an `AGENTS.md` file gather as much information from the most
important files in the project directory and synthesize the data into
`AGENTS.md`. Keep emphasis on project structure, tooling, workflows and the
default development shell. Please keep the `AGENTS.md` file minimal and focus on
stuff that is very unlikely to change about a project (e.g. a rust-based
monorepo is highly unlikely to change the root directory of its crates).

### Development shells

Most often, you will be launched in a directory that is a Nix flake and when
this is the case you will almost certainly be launched inside of the default
development shell of that Nix flake. If, for whatever reason, you are not aware
of all the tools at your disposal inside of the default development shell, you
should introduce yourself to whatever tools the default development shell
provides before doing any kind of work.

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
