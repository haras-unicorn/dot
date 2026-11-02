---
name: nix-style
description:
  Use before writing, editing or reviewing Nix code (.nix files, flakes, NixOS
  and home-manager modules, dev shells), on my own projects. My rules for the
  Nix language, its tooling, and how flakes are structured on haraspkgs.
---

# Nix style

This adds to `coding-style`, which applies too. It is my style, for my projects.
On a project that is not mine, follow that project's own style.

## Readability over brevity

The rules in this section make Nix code a bit more verbose on purpose. More
verbose is not a problem for me. Less readable is. The goal is that you can
always see where a name comes from.

Many of these are common idioms in Nix, and I do not want those idioms. There
are no idiomatic exceptions to the rules in this section.

- **Never use `with`.** Repeat yourself and write the full name each time, for
  example `pkgs.git`.
- **Never use `rec`.** Use `let ... in`. Order the bindings by what depends on
  what: a binding comes after the ones it uses.

  ```nix
  let
    a = 1;
    b = a + 2;
    c = b + 3;
  in
  c
  ```

- **Always prefix builtins with `builtins.`.** Write `builtins.map` and not
  `map`. This covers all of them, including `import`, `throw`, `abort` and
  `toString`. Never name a variable the same as a builtin.
- **Never leave unused variables, arguments or `...`.** A lambda that ignores
  its attrset argument takes `_` and not `{ ... }`. A module that takes no
  arguments is a plain attrset, because an attrset is also a module.

## Tooling

I use `nixfmt` and `nil`.

- Any format command formats with `nixfmt`.
- Any check command runs `nil diagnostics` and exits 1 if it reports anything.

`nixfmt` does not read `.editorconfig`, so the 80 columns are passed to it as
`--width 80`. Its indentation is already 2 spaces.

## Flakes

Every repository is a flake, built on
[haraspkgs](https://github.com/haras-unicorn/haraspkgs). The
`new-haraspkgs-project` skill covers setting one up, including the dev shell.

- The top-level expression of every `.nix` file in a flake is a flake-parts
  module. The exception is a small flake that only needs a `flake.nix`.
- In a repository with more than a `flake.nix`, all the Nix goes into `src/nix`,
  always. `makeFlake` gets `./src/nix`.
- Use the options haraspkgs provides as much as possible. They all start with
  `self`.
- If you need to use flake-parts directly to get around a missing option, tell
  me and add it for now. Put a comment next to it that says why haraspkgs could
  not do it. Do not leave a `TODO`, because that goes into an issue. Then tell
  me which flake introduced the bypass, why it was needed, and how to adopt the
  solution in haraspkgs, so I can write the haraspkgs issue.

## Testing

The general rules are in `coding-style`. With haraspkgs:

- Unit tests use `nix-unit` through `self.unitTests`:

  ```nix
  self.unitTests.<module-name>.<test-name> = {
    expr = 1;
    expected = 1;
  };
  ```

- Integration tests depend on the module system. NixOS tests go through
  `self.nixosTests`, which also work for home-manager. The `value` is a function
  that returns a NixOS test module, and `flake = true` makes it a check:

  ```nix
  self.nixosTests.example = {
    flake = true;

    value =
      _:
      {
        containers.agent = { };

        testScript = ''
          start_all()
          agent.succeed("true")
        '';
      };
  };
  ```

- Dev module tests go through `self.devTests`. They are written in haraspkgs
  itself, and the instructions are in the working directory there.
- An integration test only checks that the module, which is the facade, works
  with that service.

## Documentation

All the documentation is in the repo's mdbook (see `coding-style`). The options
you add get docs there, and those are generated and checked and not written by
hand:

- The format command generates them with `nix build`, using the haraspkgs docs
  helpers (`mkOptionsDocs`), and writes them into the mdbook.
- The check command builds them again and checks that they equal what is
  committed.
- Both run the generated docs through the repo's markdown formatter first,
  before writing or comparing. That is almost always prettier.

## Tunables

Module options with defaults are the Nix form of tunables (see `coding-style`).
A magic value in a module becomes an option, and the default is the value you
wanted to set.
