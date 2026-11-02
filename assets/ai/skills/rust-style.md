---
name: rust-style
description:
  Use before writing, editing or reviewing Rust code or a Cargo workspace, on my
  own projects. Workspace layout, lints, the shape of every app, libraries,
  errors, dependencies, builds, types and tests.
---

# Rust style

This adds to `coding-style`, which applies too. It is my style, for my projects.
On a project that is not mine, follow that project's own style.

## Workspace

Every repo with Rust is a Cargo workspace, even with a single crate.

- The crates live in `src/crates`, and the root `Cargo.toml` has
  `members = ["src/crates/*"]`.
- Shared metadata lives in `[workspace.package]` in the root `Cargo.toml`:
  description, repository, authors, license, readme and edition. Every crate
  inherits all of them with `.workspace = true`. Only its name and version are
  its own.
- Write the root `Cargo.toml` and the root `clippy.toml` by hand.
- Always build with the haraspkgs crane vendor, so the tools can run with
  `--unshare-all`. I only have to lock the dependencies.

```toml
# root Cargo.toml
[workspace]
resolver = "3"
members = ["src/crates/*"]
```

```toml
# every crate's Cargo.toml starts like this
[package]
name = "example"
version = "0.1.0"
description.workspace = true
repository.workspace = true
authors.workspace = true
license.workspace = true
readme.workspace = true
edition.workspace = true

[lints]
workspace = true
```

## Lints

The lints live in the root `Cargo.toml`, and every crate takes them with
`[lints] workspace = true`, always. A crate does not opt out.

```toml
[workspace.lints.rust]
unsafe_code = "deny"
missing_docs = "deny"

[workspace.lints.clippy]
unwrap_used = "deny"
expect_used = "deny"
panic = "deny"
unreachable = "deny"
todo = "deny"
unimplemented = "deny"
arithmetic_side_effects = "deny"
indexing_slicing = "deny"
string_slice = "deny"
as_conversions = "deny"
dbg_macro = "deny"
print_stdout = "deny"
print_stderr = "deny"
undocumented_unsafe_blocks = "deny"
allow_attributes_without_reason = "deny"
```

These are all `deny` and not `forbid`, so `#[allow(..., reason = "...")]` is the
way out when something is truly needed, with the reason stated (see
`coding-style`). That includes `unsafe`, `as` casts and the others.

Beyond these, heed what clippy says. When it is necessary not to, use `#[allow]`
with a reason.

Lint levels are the only clippy settings the root `Cargo.toml` can hold. Tests
need to unwrap, panic and index, so a `clippy.toml` in the root lets them:

```toml
# tests fail by panicking, so these are fine in them
allow-unwrap-in-tests = true
allow-expect-in-tests = true
allow-panic-in-tests = true
allow-indexing-slicing-in-tests = true
```

There is no setting for `arithmetic_side_effects` in tests. Where a test needs
it, use `#[allow]` with a reason.

## Builds

- Always build static binaries with musl. It follows from portability in
  `coding-style`.
- Use pure Rust crates. Use a crate that binds C only when there is literally no
  other way, and sqlite is a good example of that.
- Start from these profiles. A project can change them when it needs to, with a
  reason comment.

```toml
[profile.release]
codegen-units = 1
lto = true
opt-level = 3
strip = true

[profile.ci]
inherits = "release"
lto = false
codegen-units = 16
opt-level = 1

[profile.dev]
debug = 1

[profile.dev.package."*"]
opt-level = 3
```

The `ci` profile is for the check workflow on pull requests and similar. The
`release` profile is for release builds. The check workflow also runs with
`-D warnings`, so a warning fails it.

## Every app

Every app has the same parts:

- `clap` with derive for arguments.
- `config` for configuration. Values come from the environment as
  `<PROGRAM NAME>__<KEY>`, with `__` as the separator. The name is uppercase and
  a dash becomes an underscore, so `my-app` gives `MY_APP__KEY`. They also come
  from a config file, which is `<program name>.toml` in the current directory by
  default, or the path of a global `--config` argument. A missing default file
  is fine. A missing `--config` file is an error.
- `tracing` for logs, as JSON on stderr, and every event has a `message` field.
  This is the bare minimum, always. It is digestible for Prometheus and for a
  human with `grep` and `jq`.
- `tokio` as the async runtime, always.

`main` does only these things, each in its own file:

- Log setup, in `log.rs`.
- Argument parsing, in `args.rs`, with the `clap` structures and their tests.
- Config parsing, in `config.rs`, with the config structures and their tests.
- Passing the arguments and the config to a `run` function, in `run.rs` or a
  file like it.

Config keys are where the tunables come from (see `coding-style`). The default
of a key is the value you wanted to set.

## Libraries

Always ship a library in `src/crates`.

- A library crate holds the non-internal library code.
- A crate that is both binary and library keeps the binary setup (log, args,
  config) in the binary. The non-internal code that is not binary setup goes in
  the library.
- Every library has a `prelude` module that exports what 90% of its users would
  use.
- Document every public function with a doc comment, and with a doctest where
  possible. Ideally every public function has both, an explanation and an
  example. For many functions a doctest is impossible, and that is fine.

## Errors

- `anyhow` in the binary parts of a crate: log, args, config, the rest of the
  binary setup, and `main`.
- `thiserror` with typed errors for everything else.

## Design

- Keep the core logic in modules apart from the modules that interface with
  other libraries, frameworks and systems. The exception is when Rust idiom says
  otherwise. You cannot put `async` and `await` in a module of their own.
- Lean on the type system. Make bad behavior impossible with types. A clear
  example is an `is on` state: use one `bool` and not an `on` and an `off` flag
  that must be set together every time.

## Tests

The general rules are in `coding-style`. In Rust:

- Unit tests of the exported functions, in the same crate. An integration test
  is in its own test module.
- `wiremock` mocks other HTTP and HTTPS servers.
- An in-memory SQLite database stands in for a database.
- `testcontainers` for everything else.
