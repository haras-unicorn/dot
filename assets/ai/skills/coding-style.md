---
name: coding-style
description:
  Use before writing, editing or reviewing code in any language, on my own
  projects. My formatting, comment rules, deviations, tunables, consts and
  statics, documentation, testing, my fixed priority order, and what I care
  about when two good options conflict. Language skills add to it.
---

# Coding style

This is not a list of rules for what to type. It is how I choose when two good
options conflict. Language skills (if one exists for the language) add concrete
rules on top and do not replace this.

This is my style, for my projects. On a project that is not mine, follow that
project's own style and conventions and skip this.

I do not care about object oriented against functional. That is a language
question: functional in Rust and Nix, object oriented in C#, whatever fits. All
of the below applies to all languages.

## Deviations and comments

Everything in this file is the default. Code that strays from it needs a reason,
written as a comment next to that code. Where the language can attach the reason
to the exception, use that: in Rust, `#[allow(..., reason = "...")]`.

Straying is my call, so ask first (see Working rules). The exception is a
deviation that is well-known and idiomatic for the language or framework. Do not
ask for those. Write the comment as "idiomatic for X because Y", which is the
reason I expect to see. The comment stays, because idioms change often between
languages and frameworks and their versions.

### Deviations for a whole repository

Some projects stray from the defaults everywhere, for a reason that holds for
the whole repository. For example, a repository that is only my own machine
configurations is not a library or a product, so it needs no mdbook. Do not
comment every place that strays. Write the deviation once in that repository's
`AGENTS.md`, together with the reasoning, and treat it as the default from then
on. A deviation without written reasoning is a violation.

### Comments

A comment is for unexpected code: code that strays from the defaults, as above.
That is the only reason to write one next to code.

- Do not write comments that explain what code does. It means the code should be
  nicer to read: better names, a named variable instead of a huge expression, a
  smaller function. Clean Code by Robert C. Martin makes this case well.
- Do not leave `FIXME` or `TODO` comments. They go into issues, as a bug or a
  feature.
- Anything that documents code goes into documentation, or into doc comments in
  languages that have them (in Rust, `///` and `//!`).

## Formatting

The editorconfig below is the only formatting I ever configure or care about:

```ini
end_of_line = lf
charset = utf-8
max_line_length = 80
indent_style = space
indent_size = 2
tab_width = 2
insert_final_newline = true
trim_trailing_whitespace = true
```

I am on Linux and my screen is not huge. A file that fits in 80 columns and 2
spaces should not take more room than that.

The snippet is a reference. Editors and formatters that read `.editorconfig` get
it as is. For any that do not (`rustfmt` is one), set the same values in their
own config.

Everything else is left to whatever formatter the language uses, on purpose
unconfigured. They are good enough, and every option I set is one more thing to
carry between projects. Do not hand-format against a formatter and do not add
formatter config beyond the values above.

## File order

A file reads from the big picture down to the details. The high-level ideas and
implementations come first: the exported items and the main flow. The nitty
gritty comes after, at the bottom: helper functions, then unit tests last.

A reader who stops early has still read the important part. Where the language
forces another order, like declarations that must come before their use, follow
the language and keep the rest as close to this as it allows.

## Priorities

A hard order: safety, then performance, then features.

- Safety beats performance because a subtle vulnerability is easy to add for the
  sake of speed. I would rather have a slow and safe program than a fast and
  unsafe one.
- Features come last because putting them first piles up code debt, and then
  features stop shipping fast anyway.

This is the default. Everything else below is in service of it and never beats
it. Readable code is great, but not at the cost of safety.

## What I care about

Not an ordered list. These are the things I care about, in one place.

- **Memory, thread and object safety.** This is why I like Rust. I do not like
  getting my computer hacked.
- **Determinism.** This is why I like Nix. Every repo I start is a Nix flake,
  and Nix builds, tests and deploys. The code itself never requires Nix to
  compile or run. Rust code too should be deterministic, so tests are easy.
- **High availability and distributed.** I make a lot of web apps, so they are
  stateless and scalable by default.
- **Automation.** If I can automate it, I will.
- **Human-friendly input, output and code.**
  - Terminal and service programs: configuring them and reading their output is
    easy.
  - GUI programs: the interface is easy on the eyes and accessible.
  - Code: in our own core logic, get as close to prose as possible. When
    interfacing with other systems and libraries, it can get a bit nasty, and
    that is fine.
- **Not reinventing the wheel.** I do not depend on something for one function
  (no `isEven` package) or because it is new and shiny. Reuse what is
  well-maintained, but a new dependency is a safety question first. If a task
  tempts you to hand-roll something that already exists, suggest the existing
  thing. I reinvent things to learn, but on my own and without AI.
- **Open source, protocols and cross-platform.** Everything I make is open
  source under MIT. I prefer protocols over one company's in-house thing,
  because protocols get the good dependencies (Matrix over Discord). I keep
  things portable even if I do not ship binaries for every platform (VLC over a
  Linux-only player).
- **Boundaries and simplicity.** Every project and issue gets a clear boundary
  on what it is. Without one I start reimplementing all the software I like
  because I did not like how floating points work in my calculator app.

## Tunables, consts and statics

- No magic numbers or strings. Each one is a tunable: it comes from the
  program's configuration, and the default is the value you wanted to set.
- Well-known values, like a binary `0` or `1` or a protocol value like `404`,
  and code that happens to live in a constant, like a query snippet used in
  several queries, are not magic. They are not tunables and need no comment.
  They are well-known and do not change, so there is nothing to explain.
- Every other const gets a comment that states why it exists, because it strays
  from the rule above. For example, a config key that has to live in a const.
- Avoid statics at all costs. They make code hard to reason about, because you
  have to jump through files to see how they interact. Sometimes they are
  unavoidable. Then they get a comment that states why.

## Documentation

Every repo has an mdbook in `docs/` at the root of the repo.

- Documentation of specific items (structs, functions, traits and so on) goes
  into doc comments, where the language has them. How-tos, tutorials and the
  like go into the mdbook.
- A small project is documented in `docs/` however fits. A bigger one uses the
  [Diátaxis](https://diataxis.fr/) system.
- There is no fixed line between small and big. Eyeball it: when the free-form
  docs get gnarly or cumbersome, or Diátaxis would simply fit better, suggest
  the switch to me.

## Testing

- Test at least the happy path of every exported function.
- Unit tests live in the same file as the code they test, at the bottom of it
  (see File order).
- Test integrations in separate test modules, apart from the unit tests. An
  integration test only checks that the facade (the trait, struct or interface
  that wraps the service, library or framework) works with a real instance of
  that service.
- More important than a test is making the bad behavior impossible with good
  typing, where the language allows it.

The tools for this are in the language skills.

## Working rules

- **Invariants are 0% or 100%.** If we pick an invariant, we hold it fully. If
  we drop it, we drop it fully and look right away for what the dropped
  invariant now allows. Example: either `unsafe` is banned in this crate, or it
  is allowed only when truly necessary with a stated reason on every line that
  has it. Or we drop the ban completely and use the new power.
- **Never drop an invariant on your own.** The priority order is the default.
  Dropping something is a decision for me, per project. Ask first.
- **Stay inside the boundary.** If something to automate is outside the scope of
  what we are doing, do not do it here. Write it down as its own issue or its
  own project, and automate it there.
